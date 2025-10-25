`ifndef TB_PKG
`define TB_PKG

    `include "other_pkgs.sv"

    package tb_pkg;
        import other_pkgs::* ;

		`include "tb_defines.sv"
    endpackage

`endif // `ifndef TB_PKG
