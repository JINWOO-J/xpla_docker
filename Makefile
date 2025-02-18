
# wget https://raw.githubusercontent.com/xpladev/testnets/main/cube_47-5/genesis.json
# Mainnet
# wget https://raw.githubusercontent.com/xpladev/mainnet/main/dimension_37-1/genesis.json

VGO=go # Set to vgo if building in Go 1.10
VERSION = v1.6.0
BINARY_NAME = XPLA
REPO_HUB = jinwoo
NAME = xpla
TAGNAME := $(VERSION)
LOCAL_REPO := 20.20.1.149:5000
GIT_REPO := https://github.com/xpladev/xpla
SRC_PATH := xpla

ARCH := $(shell arch)
UNAME := $(shell uname)

LOWER_UNAME := `echo $(UNAME) | tr A-Z a-z`
BASE_IMAGE = ""

XPLA_PATH = xpla
NETWORK := testnet

GO_OS=$(shell go env GOOS)
GO_ARCH=$(shell go env GOARCH)

IS_LOCAL = true

ifeq ("$(ARCH)", "x86_64")
	ARCH = amd64
endif

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	ECHO_OPTION = "-e"
	SED_OPTION =
	DOCKER_BUILD_CMD = build

endif
ifeq ($(UNAME_S),Darwin)
	ECHO_OPTION = ""
	SED_OPTION = ''
	DOCKER_BUILD_CMD = buildx build --platform linux/arm64 --load
endif

define colorecho
      @tput setaf 6
      @echo $1
      @tput sgr0
endef

ifeq ($(IS_LOCAL), true)
	DOCKER_BUILD_OPTION = --progress=plain --no-cache --rm=true
else
	DOCKER_BUILD_OPTION = --no-cache --rm=true
endif

ifeq ($(MAKECMDGOALS) , bash)
app_minimum-gas-prices := 850000xpla
PAWN_DEBUG := true
STAT_INTERVAL := 1
MONIKER := PARA_`echo $RANDOM | md5sum | head -c 20; echo;`
app_minimum-gas-prices := "850000000000axpla"
app_evm__tracer := ""
app_evm__max-tx-gas-wanted := 0
app_json-rpc__enable := "false"
app_json-rpc__address := "0.0.0.0:8545"
app_json-rpc__gas-cap := 25000000
app_json-rpc__evm-timeout := "5s"
app_json-rpc__txfee-cap := "1"
app_json-rpc__filter-cap := "200"
app_json-rpc__feehistory-cap := "100"
app_json-rpc__logs-cap := "10000"
app_json-rpc__block-range-cap := "10000"
app_json-rpc__http-timeout := "30s"
app_json-rpc__http-idle-timeout := "2m0s"
app_json-rpc__allow-unprotected-txs := "false"
app_json-rpc__max-open-connections := 0
app_json-rpc__enable-indexer := "false"
app_json-rpc__ws-address :=  "0.0.0.0:8546"
app_json-rpc__api := "eth,net,web3,personal"
app_tls__bypass-min-fee-msg-types := "[\"/ibc.core.channel.v1.MsgRecvPacket\", \"/ibc.core.channel.v1.MsgAcknowledgement\", \"/ibc.core.client.v1.MsgUpdateClient\", \"/ibc.applications.transfer.v1.MsgTransfer\", \"/ibc.core.channel.v1.MsgTimeout\", \"/ibc.core.channel.v1.MsgTimeoutOnClose\", ]"
endif


all: build

dev: build local_push

change_version:
		$(call colorecho, "-- Change ${NAME} Version ${VERSION} --")

		@if [ -e "$(SRC_PATH)" ]; then \
    		echo "Pull the Source" ;\
    		cd $(SRC_PATH) && git pull $(GIT_REPO) $(VERSION);\
		else \
		    echo "Clone the Source" ;\
		    git clone $(GIT_REPO) $(SRC_PATH) ;\
		fi
		@cd $(SRC_PATH) && git fetch origin --tags && git checkout $(VERSION);

		@if [ '${GIT_DIRTY}' != '' ]  ; then \
				echo '[CHANGED] ${GIT_DIRTY}'; \
				git pull ;\
		fi

make_debug_mode:
	@$(shell echo $(ECHO_OPTION) "$(OK_COLOR) ----- DEBUG Environment ----- $(MAKECMDGOALS)  \n $(NO_COLOR)" >&2)\
		$(shell echo "" > DEBUG_ARGS) \
			$(foreach V, \
				$(sort $(.VARIABLES)), \
				$(if  \
					$(filter-out environment% default automatic, $(origin $V) ), \
						$($V=$($V)) \
					$(if $(filter-out "SHELL" "%_COLOR" "%_STRING" "MAKE%" "colorecho" \
									   "LOWER_UNAME%" \
									  ".DEFAULT_GOAL" "CURDIR" "TEST_FILES" "DOCKER_BUILD_%" "--%"   , "$V" ),  \
						$(shell echo $(ECHO_OPTION) '$(OK_COLOR)  $V = $(WARN_COLOR) $($V) $(NO_COLOR) ' >&2;) \
						$(shell echo '-e $V=$($V)  ' >> DEBUG_ARGS)\
					)\
				)\
			)

make_build_args:
	@$(shell echo $(ECHO_OPTION) "$(OK_COLOR) ----- Build Environment ----- \n $(NO_COLOR)" >&2)\
	   $(shell echo "" > BUILD_ARGS) \
		$(foreach V, \
			 $(sort $(.VARIABLES)), \
			 $(if  \
				 $(filter-out environment% default automatic, $(origin $V) ), \
				 	 $($V=$($V)) \
				 $(if $(filter-out "SHELL" "%_COLOR" "%_STRING" "MAKE%" "colorecho" ".DEFAULT_GOAL" "CURDIR" "TEST_FILES" "DOCKER_BUILD_OPTION" "GIT_DIRTY" "SRC_GOFILES" "DOCKER_BUILD_CMD", "$V" ),  \
					$(shell echo $(ECHO_OPTION) '$(OK_COLOR)  $V = $(WARN_COLOR) $($V) $(NO_COLOR) ' >&2;) \
				 	$(shell echo "--build-arg $V=$($V)  " >> BUILD_ARGS)\
				  )\
			  )\
		 )

test:
	docker buildx build --platform linux/amd64 --push  $(DOCKER_BUILD_OPTION) -t $(REPO_HUB)/$(NAME):$(TAGNAME) .
	#cd $(XPLA_PATH) && $(MAKE)


slim: make_build_args change_version
	docker $(DOCKER_BUILD_CMD) $(shell cat BUILD_ARGS) $(DOCKER_BUILD_OPTION) -f Dockerfile.slim -t $(REPO_HUB)/$(NAME):$(TAGNAME)-slim .


build: make_build_args change_version
	docker $(DOCKER_BUILD_CMD) $(shell cat BUILD_ARGS) $(DOCKER_BUILD_OPTION) -t $(REPO_HUB)/$(NAME):$(TAGNAME) .


build_bin:
	docker $(DOCKER_BUILD_CMD) $(shell cat BUILD_ARGS) $(DOCKER_BUILD_OPTION) -t $(REPO_HUB)/$(NAME):$(TAGNAME) .


local_push:
	docker tag $(REPO_HUB)/$(NAME):$(TAGNAME) $(LOCAL_REPO)/$(NAME):$(TAGNAME)
	docker push $(LOCAL_REPO)/$(NAME):$(TAGNAME)


push:
	docker push $(REPO_HUB)/$(NAME):$(TAGNAME)


latest:
	docker tag $(REPO_HUB)/$(NAME):$(TAGNAME) $(REPO_HUB)/$(NAME):latest
	docker push $(REPO_HUB)/$(NAME):latest


clean:
	rm -f $(SRC_PATH)

init:
	git init
	git add .
	git commit -m "init"
	git remote add origin git@github.com:JINWOO-J/$(NAME)_docker.git
	git push -u origin master

bash: make_debug_mode
	docker run $(DOCKER_CLI_OPTION) -it \
	$(shell cat DEBUG_ARGS) \
	--network bridge \
	-p 26657:26657 -p 26656:26656  \
	-e NETWORK=$(NETWORK) \
	-v $(PWD)/s6/services.d:/etc/s6/services.d -v $(PWD)/data:/data  -v $(PWD)/src:/app \
	--entrypoint /bin/bash \
	--name $(NAME) --cap-add SYS_TIME --cap-add IPC_LOCK --rm $(REPO_HUB)/$(NAME):$(TAGNAME)
