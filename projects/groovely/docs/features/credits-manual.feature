Feature: Crediting a person by hand

  Credits are always optional. No record is ever prevented from being saved by
  their absence.

  Scenario: A collector credits a person read from the sleeve notes
    Given the collector owns a record with no credits
    When the collector credits a person with the role of tenor saxophone
    Then the collector is shown that record listing that person on tenor saxophone

  Scenario: A collector marks a person as the credited artist
    Given the collector owns a record crediting Miles Davis and Bill Evans as contributors
    When the collector marks Miles Davis as the credited artist
    Then the collector is shown that record listing Miles Davis as the credited artist and Bill Evans as a contributor

  Scenario: A credit is a contributor unless marked otherwise
    Given the collector owns a record with no credits
    When the collector credits a person with the role of piano
    Then the collector is shown that record listing that person as a contributor

  Scenario: A collector credits the same person in a second role
    Given the collector owns a record crediting a person on trumpet
    When the collector credits that same person with the role of arranger
    Then the collector is shown that record listing that person in both roles
