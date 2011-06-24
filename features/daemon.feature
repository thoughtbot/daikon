Feature: Run the daikon daemon

  Scenario: Starting daikon normally should not start an HTTP server
    When I run `bundle exec ruby -Ilib ./bin/daikon start -- -k abcd`
    Then a file named "daikon.pid" should exist

  Scenario: Starting daikon with port starts HTTP server
    Given I set the "PORT" variable to "8080"
    When I run `bundle exec ruby -Ilib ./bin/daikon start -- -k abcd PORT=8080`
    Then a file named "daikon.pid" should exist
    When I wait 1 second
    And I run `curl http://0.0.0.0:8080`
    Then the output should contain "Radish: Dig deep into Redis"

  Scenario: Show version
    When I run `bundle exec ruby -Ilib ./bin/daikon --version`
    Then the output should contain the current version number
