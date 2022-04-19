---
date created: 2022-04-19 08:39
date updated: 2022-04-19 08:39
---

# What is pipeline

- receive values from upstream via inbound channels
- perform some function on that data, usually producing new values
- send values downstream via outbound channels

# Squaring numbers

- Generator Pattern converts a list of integers to a channel that emits the integers in the list

```go
func gen(nums ...int) <-chan int{
	out := make(chan int)
	go func() {
		for _, n := range nums{
			out <- n
		}
		close(out)
	}()
	return out
}
```

- receives integers from a channel and returns a channel that emits the square of each received integer

```go
func sq(in <-chan int) <-chan int{
	out := make(chan int)
	go func() {
		for n := range in{
			out <- n*n
		}
		close(out)
	}()
	return out
}
```

- receives integers from a channel and returns a channel that emits the square of each received integer

```go
func main() {
	out := gen(1,2,3,4,5,6)
	for n := range sq(out){
		fmt.Println(n)
	}
}
```

- we can compose it any number of times

```go
func main() {
	out := gen(1,2,3,4,5,6)
	for n := range sq(sq(sq(out))){
		fmt.Println(n)
	}
}
```

# Fan-out, Fan-in

- Multiple functions can read from the same channel until that channel is closed; this is called _fan-out_. This provides a way to distribute work amongst a group of workers to parallelize CPU use and I/O.
- A function can read from multiple inputs and proceed until all are closed by multiplexing the input channels onto a single channel that’s closed when all the inputs are closed. This is called fan-in.

```go
  func merge(cs ...<-chan int) <-chan int{
  	var wg sync.WaitGroup
  	wg.Add(len(cs))
  	out := make(chan int)
  
  	output := func(c <-chan int) {
  		defer wg.Done()
  		for n := range c{
  			out <- n
  		}
  	}
  
  	for _, c := range cs{
  		go output(c)
  	}
  
  	go func() {
  		wg.Wait()
  		close(out)
  	}()
  
  	return out
  }
  
  func main() {
  	out := gen(1,2,3,4,5,6)
  	c1 := sq(out)
  	c2 := sq(out)
  
  	for n := range merge(c1, c2){
  		fmt.Println(n)
  	}
  }
```

# Resource leak

- Stages don’t always receive all the inbound values

  - The receiver may only need a subset of values to make progress
  - More often, a stage exits early because an inbound value represents an error in an earlier stage
- If a stage fails to consume all the inbound values, the goroutines attempting to send those values will block indefinitely

```go
    // Consume the first value from the output.
    out := merge(c1, c2)
    fmt.Println(<-out) // 4 or 9
    return
    // Since we didn't receive the second value from out,
    // one of the output goroutines is hung attempting to send it.
}
```

- This is a resource leak: goroutines consume memory and runtime resources, and heap references in goroutine stacks keep data from being garbage collected. Goroutines are not garbage collected; they must exit on their own.
- One way to do this is to change the outbound channels to have a buffer. But it depends on knowing the number of values merge will receive and the number of values downstream stages will consume.
- Instead, we need to provide a way for downstream stages to **indicate to the senders that they will stop accepting input.**

# Explicit cancellation

We need a way to tell an unknown and unbounded number of goroutines to **stop sending their values downstream**. In Go, we can do this by **closing a channel**, **because a receive operation on a closed channel can always proceed immediately, yielding the element type’s zero value.**

```go
func gen(done <-chan struct{}, nums ...int) <-chan int{
	out := make(chan int)
	go func() {
		defer close(out)
		for _, n := range nums{
			select {
			case out <- n:
			case <-done:
				return
			}
		}
	}()
	return out
}

func sq(done <-chan struct{}, in <-chan int) <-chan int{
	out := make(chan int)
	go func() {
		defer close(out)
		for n := range in{
			select {
			case out <- n * n:
			case <-done:
				return
			}
		}
	}()
	return out
}

func merge(done <-chan struct{}, cs ...<-chan int) <-chan int{
	var wg sync.WaitGroup
	wg.Add(len(cs))
	out := make(chan int)

	output := func(c <-chan int) {
		defer wg.Done()
		for n := range c{
			select {
			case out <- n:
			case <-done:
				return
			}
		}
	}

	for _, c := range cs{
		go output(c)
	}

	go func() {
		wg.Wait()
		close(out)
	}()

	return out
}

func main() {
	// Set up a done channel that's shared by the whole pipeline,
	// and close that channel when this pipeline exits, as a signal
	// for all the goroutines we started to exit.
	done := make(chan struct{})
	defer close(done)

	in := gen(done, 1,2,3,4,5,6)
	c1 := sq(done, in)
	c2 := sq(done, in)

	for n := range merge(done, c1, c2){
		fmt.Println(n)
		done <- struct{}{}
	}
}
```

# Digesting a tree

Taking a single directory as an argument and prints the digest values for each regular file under that directory, sorted by path name.

```go
func main() {
    // Calculate the MD5 sum of all files under the specified directory,
    // then print the results sorted by path name.
    m, err := MD5All(os.Args[1])
    if err != nil {
        fmt.Println(err)
        return
    }
    var paths []string
    for path := range m {
        paths = append(paths, path)
    }
    sort.Strings(paths)
    for _, path := range paths {
        fmt.Printf("%x  %s\n", m[path], path)
    }
}
```

No concurrency and simply reads and sums each file as it walks the tree.

```go
// MD5All reads all the files in the file tree rooted at root and returns a map
// from file path to the MD5 sum of the file's contents.  If the directory walk
// fails or any read operation fails, MD5All returns an error.
func MD5All(root string) (map[string][md5.Size]byte, error) {
    m := make(map[string][md5.Size]byte)
    err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
        if err != nil {
            return err
        }
        if !info.Mode().IsRegular() {
            return nil
        }
        data, err := ioutil.ReadFile(path)
        if err != nil {
            return err
        }
        m[path] = md5.Sum(data)
        return nil
    })
    if err != nil {
        return nil, err
    }
    return m, nil
}
```

# Parallel digestion

- We split `MD5All` into a two-stage pipeline.
- The first stage, `sumFiles`, walks the tree, **digests each file in a new goroutine**, and sends the results on a channel with value type `result`
  ```go
  func sumFiles(done <-chan struct{}, root string) (<-chan result, <-chan error) {
      // For each regular file, start a goroutine that sums the file and sends
      // the result on c.  Send the result of the walk on errc.
      c := make(chan result)
      errc := make(chan error, 1)
      go func() {
          var wg sync.WaitGroup
          err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
              if err != nil {
                  return err
              }
              if !info.Mode().IsRegular() {
                  return nil
              }
              wg.Add(1)
              go func() {
                  data, err := ioutil.ReadFile(path)
                  select {
                  case c <- result{path, md5.Sum(data), err}:
                  case <-done:
                  }
                  wg.Done()
              }()
              // Abort the walk if done is closed.
              select {
              case <-done:
                  return errors.New("walk canceled")
              default:
                  return nil
              }
          })
          // Walk has returned, so all calls to wg.Add are done.  Start a
          // goroutine to close c once all the sends are done.
          go func() {
              wg.Wait()
              close(c)
          }()
          // No select needed here, since errc is buffered.
          errc <- err
      }()
      return c, errc
  }
  ```
- MD5All receives the digest values from c. MD5All returns early on error, closing done via a defer
  ```go
  func MD5All(root string) (map[string][md5.Size]byte, error) {
      // MD5All closes the done channel when it returns; it may do so before
      // receiving all the values from c and errc.
      done := make(chan struct{})
      defer close(done)          

      c, errc := sumFiles(done, root)

      m := make(map[string][md5.Size]byte)
      for r := range c {
          if r.err != nil {
              return nil, r.err
          }
          m[r.path] = r.sum
      }
      if err := <-errc; err != nil {
          return nil, err
      }
      return m, nil
  }
  ```

# Bounded parallelism

Our pipeline now has three stages: walk the tree, read and digest the files, and collect the digests.

```go
type result struct {
	path string
	sum [md5.Size]byte
	err error
}

func walkFiles(done <-chan struct{}, root string) (chan string, <-chan error) {
	paths := make(chan string)
	errc := make(chan error, 1)

	go func() {
		defer close(paths)
		// No select needed for this send, since errc is buffered.
		errc <- filepath.Walk(root, func(path string, info fs.FileInfo, err error) error {
			if err != nil {
				return err
			}
			if !info.Mode().IsRegular() {
				return nil
			}

			select {
			case paths <-path:
			case <-done:
				return errors.New("walk canceled")
			}
			return nil
		})
	}()
	return paths, errc
}

func digester(done <-chan struct{}, paths <-chan string, c chan<- result) {
	for path := range paths {
		data, err := ioutil.ReadFile(path)
		select {
		case c <- result{path, md5.Sum(data), err}:
		case <-done:
			return
		}
	}
}

func MD5All(root string)(map[string][md5.Size]byte, error){
	done := make(chan struct{})
	defer close(done)

	paths, errc := walkFiles(done, root)

	// Start a fixed number of goroutines to read and digest files.
	c := make(chan result)
	var wg sync.WaitGroup
	const numDigesters = 20
	wg.Add(numDigesters)
	for i := 0; i < numDigesters; i++ {
		go func() {
			digester(done, paths, c)
			wg.Done()
		}()
	}
	go func() {
		wg.Wait()
		close(c)
	}()

	m := make(map[string][md5.Size]byte)
	for r := range c {
		if r.err != nil {
			return nil, r.err
		}
		m[r.path] = r.sum
	}
	// Check whether the Walk failed.
	if err := <-errc; err != nil {
		return nil, err
	}
	return m, nil
}

func main() {
	// Calculate the MD5 sum of all files under the specified directory,
	// then print the results sorted by path name.
	m, err := MD5All(os.Args[1])
	if err != nil {
		fmt.Println(err)
		return
	}
	var paths []string
	for path := range m {
		paths = append(paths, path)
	}
	sort.Strings(paths)
	for _, path := range paths {
		fmt.Printf("%x  %s\n", m[path], path)
	}
}
```
