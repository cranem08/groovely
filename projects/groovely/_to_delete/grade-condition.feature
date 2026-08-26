Feature: Grade a record's condition

  Media and sleeve are graded independently on the Goldmine scale. Grading is
  optional.

  Scenario: A collector grades the media
    Given the collector owns an ungraded record
    When the collector sets that record's media condition to Very Good Plus
    Then the collector is shown that record with a media condition of Very Good Plus

  Scenario: A collector grades the sleeve differently from the media
    Given the collector owns a record with a media condition of Near Mint
    When the collector sets that record's sleeve condition to Good
    Then the collector is shown that record with a media condition of Near Mint and a sleeve condition of Good

  Scenario: A collector records a sleeve that is not the original
    Given the collector owns a record with no sleeve condition
    When the collector sets that record's sleeve condition to Generic
    Then the collector is shown that record with a sleeve condition of Generic
