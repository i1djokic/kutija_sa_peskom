# Testing

## CUnit

```bash
# Install: apt install libcunit1-dev  /  brew install cunit
# Compile: gcc -o test test.c -lcunit
```

```c
#include <CUnit/CUnit.h>
#include <CUnit/Basic.h>

// Functions to test
int add(int a, int b) { return a + b; }
int divide(int a, int b) { return b != 0 ? a / b : 0; }

// Test cases
void test_add(void) {
    CU_ASSERT(add(2, 3) == 5);
    CU_ASSERT(add(-1, 1) == 0);
    CU_ASSERT(add(0, 0) == 0);
}

void test_divide(void) {
    CU_ASSERT(divide(10, 2) == 5);
    CU_ASSERT(divide(5, 0) == 0);  // error case
}

int main(void) {
    CU_initialize_registry();
    CU_pSuite suite = CU_add_suite("math_tests", NULL, NULL);
    CU_add_test(suite, "test_add", test_add);
    CU_add_test(suite, "test_divide", test_divide);

    CU_basic_set_mode(CU_BRM_VERBOSE);
    CU_basic_run_tests();
    CU_cleanup_registry();
    return CU_get_number_of_failures() > 0;
}
```

## Check

```c
// Compile: gcc -o test test.c -lcheck
#include <check.h>

START_TEST(test_add) {
    ck_assert_int_eq(add(2, 3), 5);
    ck_assert_int_eq(add(-1, 1), 0);
}
END_TEST

START_TEST(test_divide) {
    ck_assert_int_eq(divide(10, 2), 5);
    ck_assert_int_eq(divide(5, 0), 0);
}
END_TEST

Suite *math_suite(void) {
    Suite *s = suite_create("Math");
    TCase *tc = tcase_create("Core");
    tcase_add_test(tc, test_add);
    tcase_add_test(tc, test_divide);
    suite_add_tcase(s, tc);
    return s;
}

int main(void) {
    Suite *s = math_suite();
    SRunner *sr = srunner_create(s);
    srunner_run_all(sr, CK_VERBOSE);
    int failed = srunner_ntests_failed(sr);
    srunner_free(sr);
    return failed > 0 ? 1 : 0;
}
```

## cmocka

```c
// Compile: gcc -o test test.c -lcmocka
#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>

static void test_add(void **state) {
    (void)state;
    assert_int_equal(add(2, 3), 5);
    assert_int_equal(add(-1, 1), 0);
}

static void test_divide(void **state) {
    (void)state;
    assert_int_equal(divide(10, 2), 5);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_add),
        cmocka_unit_test(test_divide),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}
```

## Makefile test target

```makefile
TEST_CFLAGS = -g -O0 -Wall -Wextra --coverage
TEST_LDFLAGS = --coverage

.PHONY: test coverage

test: test_runner
	./test_runner

test_runner: test_main.c util.c config.c
	$(CC) $(TEST_CFLAGS) -o $@ $^ -lcheck -lcunit $(TEST_LDFLAGS)

coverage: test
	gcov util.c config.c
	lcov --capture --directory . --output-file coverage.info
	genhtml coverage.info --output-directory coverage/
```

## Test project structure

```
tests/
  test_util.c
  test_config.c
  test_main.c        # test runner (main)
  mock/
    mock_network.c
  fixtures/
    test_config.yaml
```

## Simple custom test framework (no dependencies)

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TEST(name) void test_##name(void)
#define ASSERT(cond) \
    do { \
        if (!(cond)) { \
            fprintf(stderr, "FAIL: %s (%s:%d)\n", #cond, __FILE__, __LINE__); \
            failures++; \
        } \
    } while (0)
#define ASSERT_EQ(a, b) ASSERT((a) == (b))
#define ASSERT_STREQ(a, b) ASSERT(strcmp((a), (b)) == 0)

static int failures = 0;

TEST(add) {
    ASSERT_EQ(add(2, 3), 5);
    ASSERT_EQ(add(-1, 1), 0);
}

TEST(config_parse) {
    Config cfg;
    ASSERT(parse_config(&cfg, "test.yaml") == 0);
    ASSERT_EQ(cfg.port, 8080);
    ASSERT_STREQ(cfg.host, "localhost");
}

int main(void) {
    test_add();
    test_config_parse();
    printf("%s: %d tests failed\n", failures ? "FAIL" : "PASS", failures);
    return failures > 0 ? 1 : 0;
}
```
