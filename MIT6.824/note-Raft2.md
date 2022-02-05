http://nil.csail.mit.edu/6.824/2020/notes/l-raft2.txt
# topic: persistence (Lab 2C)
what would we like to happen after a server crashes?
  Raft can continue with one missing server
    but failed server must be repaired soon to avoid dipping below a majority
  two strategies:
  * replace with a fresh (empty) server
    requires transfer of entire log (or snapshot) to new server (slow)
    we *must* support this, in case failure is permanent
  * or reboot crashed server, re-join with state intact, catch up
    requires state that persists across crashes
    we *must* support this, for simultaneous power failure
  let's talk about the second strategy -- persistence