#!/bin/sh -xe

# Backend is ready
ss-set backendMysqlReady "true"
ss-display "Mysql backend Ready"

