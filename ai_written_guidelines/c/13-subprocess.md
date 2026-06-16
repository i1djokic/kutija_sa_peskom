# Subprocess & System Automation

## fork / exec / wait

```c
#include <unistd.h>
#include <sys/wait.h>
#include <stdio.h>

pid_t pid = fork();
if (pid == 0) {
    // Child process
    execlp("ls", "ls", "-la", "/tmp", NULL);
    _exit(1);  // only reached if exec fails
} else if (pid > 0) {
    // Parent process
    int status;
    waitpid(pid, &status, 0);
    if (WIFEXITED(status)) {
        printf("Exit code: %d\n", WEXITSTATUS(status));
    }
}
```

## popen (simpler, with pipe)

```c
#include <stdio.h>

FILE *fp = popen("ls -la /tmp", "r");
if (!fp) {
    perror("popen");
    return;
}

char buf[256];
while (fgets(buf, sizeof(buf), fp)) {
    printf("%s", buf);
}

int status = pclose(fp);
if (status == -1) {
    perror("pclose");
}
```

## system (simplest)

```c
#include <stdlib.h>

int ret = system("systemctl restart nginx");
if (ret == -1) {
    perror("system");
} else if (WEXITSTATUS(ret) != 0) {
    printf("Command failed with code %d\n", WEXITSTATUS(ret));
}
```

## Signal handling

```c
#include <signal.h>
#include <stdio.h>
#include <unistd.h>

volatile sig_atomic_t running = 1;

void handle_signal(int sig) {
    running = 0;
}

int main(void) {
    struct sigaction sa = {0};
    sa.sa_handler = handle_signal;
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);  // Ctrl+C

    while (running) {
        pause();  // or do work
    }

    printf("Shutting down...\n");
    return 0;
}
```

## pipe / dup2 (redirect output)

```c
int pipefd[2];
pipe(pipefd);

pid_t pid = fork();
if (pid == 0) {
    close(pipefd[0]);          // close read end
    dup2(pipefd[1], STDOUT_FILENO);  // stdout -> pipe
    close(pipefd[1]);
    execlp("date", "date", NULL);
}

close(pipefd[1]);  // close write end (parent)
char buf[256];
read(pipefd[0], buf, sizeof(buf));
printf("Got: %s", buf);
close(pipefd[0]);
```

## Daemonization

```c
void daemonize(void) {
    pid_t pid = fork();
    if (pid > 0) _exit(0);          // exit parent
    if (setsid() < 0) _exit(1);     // new session
    if (fork() > 0) _exit(0);       // not session leader
    chdir("/");
    close(STDIN_FILENO);
    close(STDOUT_FILENO);
    close(STDERR_FILENO);
}
```

## Process info

```c
#include <unistd.h>

pid_t pid = getpid();
pid_t ppid = getppid();
uid_t uid = getuid();
gid_t gid = getgid();

char cwd[1024];
getcwd(cwd, sizeof(cwd));
```

## Find and kill process by name

```c
#include <signal.h>
#include <string.h>

int kill_by_name(const char *name, int sig) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "pkill -%d %s", sig, name);
    return system(cmd);
}
```

## Practical patterns

```c
// Run command and capture output
char *run_cmd(const char *cmd) {
    FILE *fp = popen(cmd, "r");
    if (!fp) return NULL;

    char *result = malloc(4096);
    size_t pos = 0;
    int ch;
    while ((ch = fgetc(fp)) != EOF && pos < 4095) {
        result[pos++] = ch;
    }
    result[pos] = 0;
    pclose(fp);
    return result;
}

// Wait for process to finish with timeout
int wait_timeout(pid_t pid, int timeout_sec) {
    while (timeout_sec--) {
        int status;
        if (waitpid(pid, &status, WNOHANG) > 0) {
            return WEXITSTATUS(status);
        }
        sleep(1);
    }
    kill(pid, SIGTERM);
    return -1;
}
```
