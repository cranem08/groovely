Feature: Password length

  Groovely enforces a minimum and maximum password length and no other
  composition requirement.

  Scenario: A visitor chooses a password shorter than twelve characters
    Given the visitor has no Groovely account
    When the visitor submits the registration form with a password of eleven characters
    Then the visitor is shown a message stating the password must be at least twelve characters

  Scenario: A visitor chooses a long passphrase containing spaces
    Given the visitor has no Groovely account
    When the visitor submits the registration form with a ninety-character passphrase containing spaces
    Then the visitor is shown a message asking them to check their email for a verification link

  Scenario: A visitor chooses a password of exactly the maximum length
    Given the visitor has no Groovely account
    When the visitor submits the registration form with a password of one hundred and twenty eight characters
    Then the visitor is shown a message asking them to check their email for a verification link

  Scenario: A visitor chooses a password longer than the maximum
    Given the visitor has no Groovely account
    When the visitor submits the registration form with a password of one hundred and twenty nine characters
    Then the visitor is shown a message stating a password may be at most one hundred and twenty eight characters
