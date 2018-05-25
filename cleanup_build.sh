#!/bin/bash

rm ~/.ssh/td_audit.pem
cp -f ~/.ssh/config.bk ~/.ssh/config
rm -f ~/td_audit.prod.secret.exs
