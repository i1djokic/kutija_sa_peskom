# File I/O

## Opening and closing files

```c
#include <stdio.h>

FILE *fp = fopen("file.txt", "r");
if (!fp) {
    perror("fopen");
    return;
}
// ... read/write ...
fclose(fp);
```

## Modes

| Mode | Meaning |
|------|---------|
| `"r"` | Read (must exist) |
| `"w"` | Write (create/truncate) |
| `"a"` | Append (create if missing) |
| `"r+"` | Read + write (must exist) |
| `"w+"` | Read + write (create/truncate) |
| `"a+"` | Read + append (create if missing) |
| `"rb"`, `"wb"` | Binary modes |

## Reading

```c
// Character by character
int ch;
while ((ch = fgetc(fp)) != EOF) {
    putchar(ch);
}

// Line by line
char line[1024];
while (fgets(line, sizeof(line), fp)) {
    line[strcspn(line, "\n")] = 0;  // strip newline
    printf("|%s|\n", line);
}

// Formatted
int id;
char name[64];
while (fscanf(fp, "%d,%63s", &id, name) == 2) { }

// Read entire file
fseek(fp, 0, SEEK_END);
long size = ftell(fp);
rewind(fp);
char *buf = malloc(size + 1);
fread(buf, 1, size, fp);
buf[size] = 0;
```

## Writing

```c
fprintf(fp, "host=%s port=%d\n", host, port);
fputs("hello\n", fp);
fputc('A', fp);
fwrite(data, sizeof(data[0]), count, fp);
```

## Binary I/O

```c
typedef struct {
    int id;
    double value;
    char name[32];
} Record;

Record r = { .id = 1, .value = 3.14, .name = "test" };

// Write
fwrite(&r, sizeof(r), 1, fp);

// Read
Record r2;
fread(&r2, sizeof(r2), 1, fp);
```

## File operations

```c
#include <stdio.h>

remove("file.txt");         // delete
rename("old.txt", "new.txt");
tmpfile();                  // temporary file (auto-deleted)
tmpnam(NULL);               // temporary name
```

## Directory operations (POSIX)

```c
#include <dirent.h>
#include <sys/stat.h>

DIR *dir = opendir(".");
struct dirent *entry;
while ((entry = readdir(dir)) != NULL) {
    if (entry->d_type == DT_REG) {
        printf("file: %s\n", entry->d_name);
    } else if (entry->d_type == DT_DIR) {
        printf("dir:  %s\n", entry->d_name);
    }
}
closedir(dir);

// File info
struct stat st;
stat("file.txt", &st);
printf("size: %ld\n", st.st_size);
printf("perms: %o\n", st.st_mode & 0777);
printf("modified: %ld\n", st.st_mtime);
```

## Error handling

```c
#include <errno.h>
#include <string.h>

FILE *fp = fopen("nonexistent.txt", "r");
if (!fp) {
    fprintf(stderr, "Error %d: %s\n", errno, strerror(errno));
    // ENOENT: No such file or directory
    // EACCES: Permission denied
}
```

## Temporary files

```c
#include <stdlib.h>

char template[] = "/tmp/myapp_XXXXXX";
int fd = mkstemp(template);
if (fd != -1) {
    FILE *fp = fdopen(fd, "w");
    fprintf(fp, "temporary data\n");
    fclose(fp);
    unlink(template);  // delete after use
}
```
