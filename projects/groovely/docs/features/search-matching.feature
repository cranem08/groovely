Feature: What counts as a match

  Matching is on word beginnings, ignoring case and accents, and every term in the
  query must match.

  Scenario: A collector types the beginning of a word
    Given the collector owns a record by John Coltrane and a record by Bill Evans
    When the collector searches the artist scope for Colt
    Then the collector is shown only the record by John Coltrane

  Scenario: A collector types the minimum two characters
    Given the collector owns a record by John Coltrane and a record by Bill Evans
    When the collector searches the artist scope for Co
    Then the collector is shown only the record by John Coltrane

  Scenario: A collector types the middle of a word
    Given the collector owns a record by John Coltrane and a record by Bill Evans
    When the collector searches the artist scope for rane
    Then the collector is shown a message stating no records matched

  Scenario: A collector types two terms in either order
    Given the collector owns a record titled Kind of Blue by Miles Davis and a record titled Blue Train by John Coltrane
    When the collector searches the album scope for blue kind
    Then the collector is shown only the record titled Kind of Blue

  Scenario: A single term matches every record carrying that word
    Given the collector owns a record titled Kind of Blue and a record titled Blue Train
    When the collector searches the album scope for blue
    Then the collector is shown both of those records

  Scenario: A collector types a term matching only one record of two
    Given the collector owns a record titled Kind of Blue and a record titled Blue Train
    When the collector searches the album scope for blue train
    Then the collector is shown only the record titled Blue Train

  Scenario: A collector omits an accent the record carries
    Given the collector owns a record by Antonín Dvořák and a record by Bill Evans
    When the collector searches the artist scope for Dvorak
    Then the collector is shown only the record by Antonín Dvořák

  Scenario: A collector types an accent the record does not carry
    Given the collector owns a record by Muller spelled with no umlaut and a record by Bill Evans
    When the collector searches the artist scope for Müller
    Then the collector is shown only the record by Muller

  Scenario: A collector types a single character
    Given the collector owns a record by John Coltrane and a record by Bill Evans
    When the collector searches the artist scope for the single character c
    Then the collector is shown both of those records
