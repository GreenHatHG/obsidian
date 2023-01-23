# Backup

```shell
docker exec CONTAINER_NAME pg_dump -U USERNAME -d DATABASE_NAME -Fc > backup.custom
```

- `-Fc` flag to backup in the custom format, this will create a binary file which will be smaller in size.

- `-Fp` flag to backup in the plain text format, this will create a text file which will be larger in size.

# Restore

```shell
docker exec -i CONTAINER_NAME pg_restore -U USERNAME -d DATABASE_NAME -Fc -C --no-acl --no-owner -j NUM_JOBS < backup.custom
```

- The `-Fc` flag tells pg_restore that the file was created with the custom format and `-C` will clean(drop) the database before restore.

- To ignore SQL errors during the restore process, you can use the `--no-acl` and `--no-owner` options, which will cause pg_restore to skip over any ACLs and ownership settings that might cause errors

