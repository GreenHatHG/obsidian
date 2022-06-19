# Client Block

- **TCP  listen backlog**: When multiple clients connect to the server, the server then **holds the incoming requests in a queue**. The clients are arranged in the queue, and the server processes their requests one by one as and when queue-member proceeds. The nature of this kind of connection is called queued connection.

- The `backlog` parameter specifies the number of pending connections the queue will hold.

    ```c
    int listen(int sockfd, int backlog);
    ```

[python - What is "backlog" in TCP connections? - Stack Overflow](https://stackoverflow.com/questions/36594400/what-is-backlog-in-tcp-connections)

