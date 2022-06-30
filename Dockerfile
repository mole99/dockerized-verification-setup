# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0

# syntax=docker/dockerfile:1
FROM ubuntu:20.04 AS build

RUN apt update

# install general utils
RUN DEBIAN_FRONTEND="noninteractive" \
    apt install --assume-yes --no-install-recommends tzdata
RUN apt install --assume-yes --no-install-recommends \
    git ca-certificates
    
# install iverilog dependencies
RUN apt install --assume-yes --no-install-recommends \
    make gcc g++ bison flex gperf libreadline6-dev libncurses5-dev autoconf

# fetch iverilog
RUN git clone https://github.com/steveicarus/iverilog.git

# build iverilog
RUN cd iverilog && \
    sh autoconf.sh && \
    ./configure && \
    make -j$(nproc) && \
    make install

# install riscv toolchain dependencies
RUN apt install --assume-yes --no-install-recommends \
    autoconf automake autotools-dev curl python3 libmpc-dev \
    libmpfr-dev libgmp-dev gawk build-essential bison flex \
    texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev

# fetch riscv toolchain
RUN git clone https://github.com/riscv/riscv-gnu-toolchain riscv-gnu-toolchain-rv32i && \
    cd riscv-gnu-toolchain-rv32i && \
    git submodule update --init --recursive

# build riscv toolchain
RUN cd riscv-gnu-toolchain-rv32i && \
    mkdir /opt/riscv32i && \
    mkdir build; cd build && \
    ../configure --with-arch=rv32i --prefix=/opt/riscv32i && \
    make -j$(nproc)

FROM ubuntu:20.04

COPY --from=build "/usr/local" "/usr/local"
COPY --from=build "/opt/riscv32i" "/opt/riscv32i"

ENV GCC_PATH=/opt/riscv32i/bin
ENV DV_ROOT=/dv_root

WORKDIR $DV_ROOT

CMD /bin/bash
