# CLI Tools

## getopt (POSIX)

```c
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    int opt;
    int verbose = 0;
    int port = 8080;
    char *host = "localhost";

    while ((opt = getopt(argc, argv, "vh:p:")) != -1) {
        switch (opt) {
        case 'v':
            verbose = 1;
            break;
        case 'h':
            host = optarg;
            break;
        case 'p':
            port = atoi(optarg);
            break;
        default:
            fprintf(stderr, "Usage: %s [-v] [-h host] [-p port]\n", argv[0]);
            return EXIT_FAILURE;
        }
    }
}
```

## getopt_long (GNU extension)

```c
static struct option long_options[] = {
    {"verbose", no_argument,       0, 'v'},
    {"host",    required_argument, 0, 'h'},
    {"port",    required_argument, 0, 'p'},
    {"help",    no_argument,       0,  0 },
    {0, 0, 0, 0}
};

int main(int argc, char *argv[]) {
    int opt;
    int option_index = 0;

    while ((opt = getopt_long(argc, argv, "vh:p:", long_options, &option_index)) != -1) {
        if (opt == 0) {
            // long option only (e.g., --help)
            if (long_options[option_index].name[0] == 'h') {
                printf("Usage: %s [options]\n", argv[0]);
                return 0;
            }
        }
        switch (opt) {
        case 'v': /* ... */ break;
        case 'h': /* ... */ break;
        case 'p': /* ... */ break;
        }
    }
}
```

## argp (GNU, stdlib)

```c
#include <argp.h>

static const char doc[] = "Automation tool -- a simple CLI example.";
static const char args_doc[] = "INPUT";

static struct argp_option options[] = {
    {"verbose", 'v', 0, 0, "Verbose output"},
    {"output",  'o', "FILE", 0, "Output file"},
    {"port",    'p', "PORT", 0, "Port number"},
    {0}
};

struct Arguments {
    char *input;
    char *output;
    int port;
    int verbose;
};

static error_t parse_opt(int key, char *arg, struct argp_state *state) {
    struct Arguments *a = state->input;
    switch (key) {
    case 'v': a->verbose = 1; break;
    case 'o': a->output = arg; break;
    case 'p': a->port = atoi(arg); break;
    case ARGP_KEY_ARG:
        if (state->arg_num >= 1) argp_usage(state);
        a->input = arg;
        break;
    case ARGP_KEY_END:
        if (state->arg_num < 1) argp_usage(state);
        break;
    default: return ARGP_ERR_UNKNOWN;
    }
    return 0;
}

int main(int argc, char *argv[]) {
    struct Arguments a = { .port = 8080 };
    static struct argp argp = { options, parse_opt, args_doc, doc };
    argp_parse(&argp, argc, argv, 0, 0, &a);
    return 0;
}
```

## Exit codes

```c
#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1
#define EXIT_CONFIG_ERROR 2
#define EXIT_NETWORK_ERROR 3

#define EX_USAGE 64     // from <sysexits.h> on BSD
#define EX_NOINPUT 66
#define EX_PROTOCOL 76
```

## Environment variables

```c
#include <stdlib.h>

const char *home = getenv("HOME");
const char *debug = getenv("DEBUG");
int verbose = debug && strcmp(debug, "1") == 0;

// Set
setenv("MYAPP_CONFIG", "/etc/myapp.yaml", 1);
// unsetenv("MYAPP_CONFIG");
```

## Common CLI pattern

```c
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <errno.h>
#include <string.h>

static void usage(const char *prog) {
    fprintf(stderr, "Usage: %s [options] <command>\n", prog);
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  -v, --verbose    Verbose output\n");
    fprintf(stderr, "  -h, --host HOST  Target host (default: localhost)\n");
    fprintf(stderr, "  -p, --port PORT  Target port (default: 8080)\n");
}

int main(int argc, char *argv[]) {
    int verbose = 0;
    char *host = "localhost";
    int port = 8080;

    static struct option opts[] = {
        {"verbose", no_argument,       NULL, 'v'},
        {"host",    required_argument, NULL, 'h'},
        {"port",    required_argument, NULL, 'p'},
        {"help",    no_argument,       NULL,  0 },
        {NULL, 0, NULL, 0}
    };

    int c;
    while ((c = getopt_long(argc, argv, "vh:p:", opts, NULL)) != -1) {
        switch (c) {
        case 'v': verbose = 1; break;
        case 'h': host = optarg; break;
        case 'p':
            port = atoi(optarg);
            if (port <= 0 || port > 65535) {
                fprintf(stderr, "Invalid port: %d\n", port);
                return EXIT_FAILURE;
            }
            break;
        case 0:
            usage(argv[0]);
            return EXIT_SUCCESS;
        default:
            usage(argv[0]);
            return EXIT_FAILURE;
        }
    }

    if (optind >= argc) {
        fprintf(stderr, "Error: missing command\n");
        usage(argv[0]);
        return EXIT_FAILURE;
    }

    printf("Running on %s:%d (verbose=%d)\n", host, port, verbose);
    return EXIT_SUCCESS;
}
```
