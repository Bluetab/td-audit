# Changelog

## [4.31.0] 2021-11-02

### Fixed

- [TD-4211] Subscriptions on data structures include structure note events
- [TD-4134] `taxonomy_roles` notifications

## [4.29.0] 2021-10-04

### Added

- [TD-3396] Add notification `read mark`

## [4.28.0] 2021-09-20 

### Added

- [TD-3971] Template mandatory dependent field
- [TD-3780] `taxonomy_role` subscriber type support

## [4.27.0] 2021-09-07

### Added

- [TD-3951] Notifications included for grants
- [TD-3910] Notifications included for structures notes status changes

### Changed

- [TD-3973] Update td-df-lib for default values in swith fields

## [4.26.0] 2021-08-16

### Changed

- [TD-3987] Include `cursor` with `id` and `size` on events search

## [4.25.0] 2021-07-26

### Changed

- Updated dependencies

## [4.24.0] 2021-07-13

### Added

- [TD-3724] Notifications when document is shared

## [4.22.0] 2021-06-15

### Added

- [TD-3735] Notifications for tag related events

## [4.21.0] 2021-05-31

### Changed

- [TD-3503] Share notification: Retrieve user emails by id
- [TD-3753] Build using Elixir 1.12 and Erlang/OTP 24
- [TD-3502] Update td-cache and td-df-lib

## [4.20.0] 2021-05-17

### Changed

- Security patches from `alpine:3.13`
- Update dependencies

## [4.19.0] 2021-05-04

### Added

- [TD-3346] Search events Api

## Fixed

- [TD-3618] Exception sending email

## [4.17.0] 2021-04-05

### Changed

- [TD-3445] Postgres port configurable through `DB_PORT` environment variable

## [4.16.0] 2021-03-22

### Added

- [TD-1389] Enable to filter events by timestamp range and event type

## [4.15.0] 2021-03-08

### Added

- [TD-3063] Subscription filter in scope

### Changed

- [TD-3055] User notifications endpoint
- Updated to Bamboo 2.0.x and Bamboo SMTP 4.0.0
- Build with `elixir:1.11.3-alpine`, runtime `alpine:3.13`

## [4.14.0] 2021-02-22

### Changed

- [TD-3265] Url for concept resources in notifications
- [TD-3245] Tested compatibility with PostgreSQL 9.6, 10.15, 11.10, 12.5 and
  13.1. CI pipeline changed to use `postgres:12.5-alpine`.

### Removed

- [TD-3171] Kubernetes jobs are no longer launched by `td-audit`

## [4.13.0] 2021-02-08

### Changed

- [TD-3262] Secure Subscription API and add resources

## [4.12.0] 2021-01-25

### Added

- [TD-3074] Endpoint to share notifications

### Changed

- [TD-3163] Auth tokens now include `role` claim instead of `is_admin` flag
- [TD-3182] Allow to use redis with password

## [4.11.0] 2021-01-11

### Added

- [TD-2301] Subscription under `relation_deprecated` event

### Changed

- [TD-3170] Build docker image which runs with non-root user

### Added

- [TD-2865] Notifications for concept related events

## [4.9.0] 2020-11-30

### Changed

- [TD-3124] Update dependencies (quantum 3.3.0 and others)

## [4.7.0] 2020-11-03

### Added

- [TD-2952] Support for launching data quality jobs in Kubernetes

## [4.5.0] 2020-10-05

### Changed

- [TD-2939] Limit simultaneous sending of emails

## [4.2.0] 2020-08-17

### Changed

- [TD-2810] `tls` as environment variable
- [TD-2532] User-Rule Subscriptions

## [4.1.0] 2020-07-23

### Fixed

- [TD-2846] Subscriptions with notifications could not be deleted

## [4.0.0] 2020-07-01

### Added

- [TD-2637] Audit events are now read from the Redis stream `audit:events`

### Changed

- [TD-2637] Renamed events:
  - event `create_comment` is now `comment_created`
  - event `add_relation` is now `relation_created`
  - event `delete_relation` is now `relation_deleted`
  - event `concept_sent_for_approval` is now `concept_submitted`
  - resource type `business_concept` renamed to `concept` for events from
    service `td_lm`

### Removed

- [TD-2637] Removed routes:
  - `POST /api/audits`
  - `DELETE /api/events/:id`
  - `PATCH /api/events/:id`
  - `PUT /api/events/:id`

## [3.20.0] 2020-04-20

### Added

- [TD-2500] Support bulk subscription for all users with a role on existing
  business concepts. For example, to subscribe data owners to comment
  notifications on their business concepts:
  ```
  PATCH /api/subscriptions
  {
    "subscriptions": {
      "role": "data_owner",
      "event": "comment_created",
      "resource_type": "business_concept",
      "periodicity": "daily"
    }
  }
  ```

### Changed

- [TD-2508] Update to Elixir 1.10

## [3.8.0] 2019-10-14

### Changed

- [TD-1987] Change text in table header of Rule Notification email

## [3.5.1] 2019-09-03

### Fixed

- [TD-2081] Event stream consumer did not respect redis_host and port config
  options

## [3.5.0] 2019-09-02

### Added

- [TD-1907] Notification under failed rule results

## [3.2.0] 2019-07-24

### Changed

- [TD-2002] Update td-cache and delete permissions list from config

## [3.1.0] 2019-07-08

### Changed

- [TD-1618] Cache improvements (use td-cache instead of td-perms)
- [TD-1924] Use Jason instead of Poison for JSON encoding/decoding

### Removed

- Changes to business concept link count & rule count are now reindexed by bg

## [2.19.0] 2019-05-14

### Fixed

- [TD-1774] Newline is missing in logger format

### Changed

- [TD-1660] Will only update business concept link_count on
  add_relation/delete_relation event if "target_type" is "data_field"
- Update to phoenix 1.4, ecto 3.0, exq 0.13, redix 0.8.2

## [2.16.0] 2019-04-01

### Added

- [TD-1571] Elixir's Logger config will check for EX_LOGGER_FORMAT variable to
  override format

## [2.7.0] 2018-01-17

### Changed

- Modified the identifiers of those events creating or deleting links

### Changed

- Completed notification engine for create_comment events

## [2.6.3] 2018-11-22

### Changed

- Completed notification engine for create_comment events

## [2.6.2] 2018-11-12

### Changed

- Subscrition event processor get email from cache by full_name
