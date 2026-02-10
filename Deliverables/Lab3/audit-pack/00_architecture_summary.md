# Overview

We have two regions. The two regions run behind a cloudfront distribution in an active-active configuration.

## Tokyo

The Tokyo region includes the following:

- EC2 instance with web application
- RDS instance
- ALB

## Sao Paulo

The Sao Paulo region includes the following:

- EC2 instance with web application
- ALB
  _The Sao Paulo region will never have a copy of the data. It will only read from the RDS instance in Tokyo_
