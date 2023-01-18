Dropping a note here about the tests.

The automated tests run a set of tests on different platforms that tests
installing this feature with no parameters. For this feature, these tests
are expected to fail.

The tests that should not fail for this feature are the scenario tests. These
run the tests with parameters and perform actual git operations etc.