# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## v2.4.1 - 2021-03-03

- Fix email address encoding in `PutSuppressedDestination` `DeleteSuppressedDestination` by @mtarnovan
- Switch to from Poison to Jason

## v2.4.0 - 2022-03-21

- Add v2 API's [PutSuppressedDestination](https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_PutSuppressedDestination.html) by @mtarnovan
- Add v2 API's [DeleteSuppressedDestination](https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_DeleteSuppressedDestination.html) by @mtarnovan

## v2.3.0 - 2021-05-02

- Add functions for custom verification emails by @wmnnd

## v2.2.0 - 2021-04-23

- Add CRUD actions on contact list and contact resources by j4p3
- Add v2 API's [SendEmail](https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_SendEmail.html) action by j4p3

## v2.1.1 - 2019-09-12

- Added support of `ReplyToAddresses.member.N` option to [SendBulkTemplatedEmail](https://docs.aws.amazon.com/ses/latest/APIReference/API_SendBulkTemplatedEmail.html) action by @flyrboy96
- Spec improvements by @flyrboy96

## v2.1.0 - 2019-03-09

- Added support of [CreateTemplate](https://docs.aws.amazon.com/ses/latest/APIReference/API_CreateTemplate.html) action by @themerch
- Added support of [DeleteTemplate](https://docs.aws.amazon.com/ses/latest/APIReference/API_DeleteTemplate.html) action by @themerch
- Added support of [SendBulkTemplatedEmail](https://docs.aws.amazon.com/ses/latest/APIReference/API_SendBulkTemplatedEmail.html) action by @themerch

## v2.0.2 - 2018-08-08

- Added support for [SendTemplatedEmail](https://docs.aws.amazon.com/ses/latest/APIReference/API_SendTemplatedEmail.html) action with exception for two optional parameters: `TemplateArn` and `ReplyToAddresses.member.N`. by @xfumihiro
- Fixed wrong key in destination typespec by @kalys
- Fixed broken typespec contracts

## v2.0.1 - 2018-06-27

- Improved Mix configuration

## v2.0.0 - 2017-11-10

- Major Project Split. Please see the main ExAws repository for previous changelogs.
