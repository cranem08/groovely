Feature: Camera unavailable

  Scanning is never the only way to add a record, and a camera that cannot be used
  says so rather than failing silently.

  Scenario: A collector declines camera access
    Given the collector has declined camera access
    When the collector opens the add record screen
    Then the collector is shown a message stating the camera is unavailable

  Scenario: A collector uses a device with no camera
    Given the collector is using a device with no camera
    When the collector opens the add record screen
    Then the collector is shown a message stating no camera was found

  Scenario: Manual entry when the camera cannot be used
    Given the collector has been told the camera is unavailable
    When the collector submits an artist and a title by manual entry
    Then the collector is shown the new record in their collection
