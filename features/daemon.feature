Feature: Run the daikon daemon

  Scenario: Starting daikon normally starts a daemon
    When I run `bundle exec ruby -Ilib ./bin/daikon start -- -k abcd`
    Then a file named "daikon.pid" should exist

  Scenario: Show version
    When I run `bundle exec ruby -Ilib ./bin/daikon --version`
    Then the output should contain the current version number
