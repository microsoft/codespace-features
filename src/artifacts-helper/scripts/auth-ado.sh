#!/bin/bash
if [ -f "${HOME}/ado-auth-helper" ]; then
  ARTIFACTS_ACCESSTOKEN=$(${HOME}/ado-auth-helper get-access-token)
fi