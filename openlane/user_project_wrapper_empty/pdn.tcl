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

# Power nets
if { ! [info exists ::env(VDD_NET)] } {
	set ::env(VDD_NET) $::env(VDD_PIN)
}

if { ! [info exists ::env(GND_NET)] } {
	set ::env(GND_NET) $::env(GND_PIN)
}

set ::power_nets $::env(VDD_NET)
set ::ground_nets $::env(GND_NET)


pdngen::specify_grid stdcell {
    name grid
	core_ring {
		$::env(FP_PDN_LOWER_LAYER) {width $::env(FP_PDN_CORE_RING_VWIDTH) spacing $::env(FP_PDN_CORE_RING_VSPACING) core_offset $::env(FP_PDN_CORE_RING_VOFFSET)}
		$::env(FP_PDN_UPPER_LAYER) {width $::env(FP_PDN_CORE_RING_HWIDTH) spacing $::env(FP_PDN_CORE_RING_HSPACING) core_offset $::env(FP_PDN_CORE_RING_HOFFSET)}

	}
	rails {
	}
    straps {
    }
    connect {{met4 met5}}
}
