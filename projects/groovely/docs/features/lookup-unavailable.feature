Feature: Lookup unavailable

  No failure of the external music database may prevent a record being added.

  Scenario: The external music database is unreachable
    Given the external music database is unreachable
    When the collector scans a barcode
    Then the collector is shown a message offering manual entry because lookups are temporarily unavailable

  Scenario: The external music database rate limit has been reached
    Given the external music database has refused further requests for the current minute
    When the collector scans a barcode
    Then the collector is shown a message offering manual entry because lookups are temporarily unavailable

  Scenario: The external music database does not respond within ten seconds
    Given the external music database responds no sooner than ten seconds
    When the collector scans a barcode
    Then the collector is shown a message offering manual entry because lookups are temporarily unavailable

  Scenario: A collector adds a record while the external music database is unreachable
    Given the external music database is unreachable
    When the collector submits an artist and a title by manual entry
    Then the collector is shown the new record in their collection

  Scenario: A candidate release missing some fields
    Given the external music database returns a release carrying no country and no release year
    When the collector confirms that candidate release
    Then the collector is shown the new record carrying that release's artist and title with its country and release year empty
