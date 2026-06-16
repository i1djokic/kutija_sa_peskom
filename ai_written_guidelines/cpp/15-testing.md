# Testing

## Google Test

```cmake
# CMakeLists.txt
include(FetchContent)
FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/release-1.14.0.tar.gz
)
FetchContent_MakeAvailable(googletest)
```

```cpp
#include <gtest/gtest.h>

// Function to test
int add(int a, int b) { return a + b; }

TEST(MathTest, Add) {
    EXPECT_EQ(add(2, 3), 5);
    EXPECT_EQ(add(-1, 1), 0);
    EXPECT_EQ(add(0, 0), 0);
}

TEST(MathTest, AddNegative) {
    EXPECT_LT(add(-5, -3), 0);
}

// Fixtures
class ConfigTest : public ::testing::Test {
protected:
    void SetUp() override {
        cfg_ = Config::from_yaml("test.yaml");
    }

    void TearDown() override {
        // cleanup
    }

    Config cfg_;
};

TEST_F(ConfigTest, LoadsPort) {
    EXPECT_EQ(cfg_.port(), 8080);
}

TEST_F(ConfigTest, LoadsHost) {
    EXPECT_EQ(cfg_.host(), "localhost");
}

int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
```

### Matchers

```cpp
EXPECT_THAT(value, ::testing::Eq(42));
EXPECT_THAT(str, ::testing::StartsWith("http"));
EXPECT_THAT(list, ::testing::SizeIs(5));
EXPECT_THAT(list, ::testing::Contains("item"));
EXPECT_THAT(map, ::testing::Contains(testing::Pair("key", 42)));
```

## Catch2

```cpp
// #include <catch2/catch_test_macros.hpp>
#define CATCH_CONFIG_MAIN
#include <catch2/catch.hpp>

int factorial(int n) {
    return n <= 1 ? 1 : n * factorial(n - 1);
}

TEST_CASE("Factorial", "[math]") {
    REQUIRE(factorial(0) == 1);
    REQUIRE(factorial(1) == 1);
    REQUIRE(factorial(5) == 120);
}

TEST_CASE("String operations", "[string]") {
    std::string s = "hello world";

    SECTION("length") {
        REQUIRE(s.length() == 11);
    }

    SECTION("contains") {
        REQUIRE(s.find("world") != std::string::npos);
    }
}

// BDD style
SCENARIO("deploying an application") {
    GIVEN("a valid config") {
        Config cfg{"test.yaml"};

        WHEN("deploying to production") {
            auto result = deploy(cfg, "production");

            THEN("it should succeed") {
                REQUIRE(result == true);
            }
        }
    }
}
```

## Benchmark (Google Benchmark)

```cpp
#include <benchmark/benchmark.h>

static void BM_ParseConfig(benchmark::State& state) {
    for (auto _ : state) {
        Config::from_yaml("large_config.yaml");
    }
}
BENCHMARK(BM_ParseConfig);

static void BM_VectorPush(benchmark::State& state) {
    for (auto _ : state) {
        std::vector<int> v;
        for (int i = 0; i < state.range(0); i++) v.push_back(i);
    }
}
BENCHMARK(BM_VectorPush)->Range(8, 8<<10);

BENCHMARK_MAIN();
```

## Mocking (Google Mock)

```cpp
#include <gmock/gmock.h>

class NetworkInterface {
public:
    virtual ~NetworkInterface() = default;
    virtual bool ping(const std::string& host) = 0;
};

class MockNetwork : public NetworkInterface {
public:
    MOCK_METHOD(bool, ping, (const std::string&), (override));
};

TEST(ServiceTest, PingsHost) {
    MockNetwork net;
    EXPECT_CALL(net, ping("example.com"))
        .Times(1)
        .WillOnce(testing::Return(true));

    Service svc(&net);
    EXPECT_TRUE(svc.check("example.com"));
}
```

## Makefile test target

```makefile
.PHONY: test coverage

test: build_test
	./build/test_runner

build_test:
	cmake -S . -B build -DBUILD_TESTS=ON
	cmake --build build

coverage: test
	lcov --capture --directory . --output-file coverage.info
	genhtml coverage.info --output-directory coverage/
```
