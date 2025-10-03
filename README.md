# Truedat Audit

TdAudit is a back-end service developed as part of the Truedat project that
supports audit events and notifications.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

Install dependencies with `mix deps.get`

To start your Phoenix server:

### Installing

- Create and migrate your database with `mix ecto.create && mix ecto.migrate`
- Start Phoenix endpoint with `mix phx.server`

- Now you can visit [`localhost:4007`](http://localhost:4007) from your browser.

## Running the tests

Run all aplication tests with `mix test`

## Environment variables

- `REDIS_AUDIT_STREAM_MAXLEN` (Optional) Maximum length for Redis audit stream. Default: 100
- `REDIS_STREAM_MAXLEN` (Optional) Maximum length for Redis stream. Default: 100

### SSL Connection

- `DB_SSL`: Boolean value to enable SSL configuration. Default is `false`.
- `DB_SSL_CACERTFILE`: Path to the Certification Authority (CA) certificate file, e.g. `/path/to/ca.crt`.
- `DB_SSL_VERSION`: Supported versions are `tlsv1.2` and `tlsv1.3`. Default is `tlsv1.2`.
- `DB_SSL_CLIENT_CERT`: Path to the client SSL certificate file.
- `DB_SSL_CLIENT_KEY`: Path to the client SSL private key file.
- `DB_SSL_VERIFY`: Specifies whether server certificates should be verified (`true`/`false`).

## Built With

- [Phoenix](http://www.phoenixframework.org/) - Web framework
- [Ecto](http://www.phoenixframework.org/) - Phoenix and Ecto integration
- [Postgrex](http://hexdocs.pm/postgrex/) - PostgreSQL driver for Elixir
- [Cowboy](https://ninenines.eu) - HTTP server for Erlang/OTP
- [credo](http://credo-ci.org/) - Static code analysis tool for the Elixir language
- [guardian](https://github.com/ueberauth/guardian) - Authentication library

## Authors

- **Bluetab Solutions Group, SL** - _Initial work_ - [Bluetab](http://www.bluetab.net)

See also the list of [contributors](https://github.com/bluetab/td-audit) who participated in this project.

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.

In order to use this software, it is necessary that, depending on the type of functionality that you want to obtain, it is assembled with other software whose license may be governed by other terms different than the GNU General Public License version 3 or later. In that case, it will be absolutely necessary that, in order to make a correct use of the software to be assembled, you give compliance with the rules of the concrete license (of Free Software or Open Source Software) of use in each case, as well as, where appropriate, obtaining of the permits that are necessary for these appropriate purposes.
