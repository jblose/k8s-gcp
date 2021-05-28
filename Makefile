UNAME_S              := $(shell uname -s)
TARGET_ENV           ?= $(shell basename `pwd`)

# Check the system keychain for stored encryption pass
ifeq ($(UNAME_S),Linux)
endif
ifeq ($(UNAME_S),Darwin)
	ENCRYPTION_PASS ?= $(shell security find-generic-password -a "${USER}" -s "$(KEYCHAIN_PREFIX)/$(TARGET_ENV)" -w)
endif
# Check keepass for stored encryption pass if not available in OS keychain
ifeq ($(ENCRYPTION_PASS),)
	ifneq ($(shell which keepassxc-cli),)
		ENCRYPTION_PASS := $(shell keepassxc-cli show "$(KEEPASS_DB_PATH)" "$(KEEPASS_ENTRY)" -s -a password)
	endif
endif

.PHONY: test all clean tf-init encrypt-secrets decrypt-secrets

dep:
	terraform get -update

tf-init: dep
	terraform init

tf-plan: tf-init dep
	terraform plan -out "out.plan"

ifneq ($(ENCRYPTION_PASS),)
decrypt-secrets:
	@openssl enc -d -aes-256-cbc -pass "pass:${ENCRYPTION_PASS}" -in "secrets.tfvars.enc" -out "secrets.tfvars"

encrypt-secrets:
	@openssl enc -aes-256-cbc -pass "pass:${ENCRYPTION_PASS}" -in "secrets.tfvars" -out "secrets.tfvars.enc"

else
decrypt-secrets:
	@echo "ENCRYPTION_PASS is not set."

encrypt_secrets:
	@echo "ENCRYPTION_PASS is not set."

endif

