# cocotb Makefile — TRI-1 Max
# Apache-2.0
SIM ?= icarus
FST ?= -fst
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = tt_um_trinity_max_true.v trinity_max_true_dual.v trinity_quad_mesh.v trinity_mesh_2x2.v trinity_router_2x2.v trinity_gf16_tile.v trinity_master_fsm.v gf16_mul.v gf16_add.v gf16_dot4.v gf16_dot8.v phi_anchor_post.v lucas_rom.v vsa_matmul_8x8.v vsa_matmul_16x16.v bitnet_encoder.v bpb_counter.v blake3_anchor.v multi_tile_receipt.v crc32_receipt.v alu9_decoder.v ring27_memory.v hwrng_lfsr.v phi_pll_div.v wb_status_reg.v wishbone_full.v

ifneq ($(GATES),yes)
SIM_BUILD = sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))
else
SIM_BUILD = sim_build/gl
COMPILE_ARGS += -DGL_TEST -DFUNCTIONAL -DUSE_POWER_PINS -DSIM -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v
endif

COMPILE_ARGS += -I$(SRC_DIR)
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb
COCOTB_TEST_MODULES = test
include $(shell cocotb-config --makefiles)/Makefile.sim
