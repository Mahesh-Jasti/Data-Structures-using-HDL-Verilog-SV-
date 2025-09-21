module skid #(parameter OPT = 4, DW = 10)
(
    input valid_in,
    input [DW-1:0] data_in,
    output logic ready_out,
    
    input ready_in,
    output logic [DW-1:0] data_out,
    output logic valid_out,
    
    input clk,
    input rstb
);

// Skid buffer with multiple implementations controlled by OPT parameter.
// DW - data width
// OPT 0-6 implements various levels of backpressure handling.

//    Input                       Output
//    -----                       ------
//             ---------------
//    ready <--|             |<-- ready
//    valid -->| Skid Buffer |--> valid
//    data  -->|             |--> data
//             ---------------

//   P : Producer
//   S : Skid Buffer
//   C : Consumer


//   Before Skid Buffer
//   -----           -----
//       |   valid   |
//       |---------->|
//       |           |
//       |   data    |
//    P  |---------->|  C
//       |           |
//       |   ready   |
//       |<----------|
//   -----           -----


//  After Skid Buffer insertion
//   -----            ------------           -----
//       | ready_out |           | ready_in  |
//       |<----------|           |<----------|
//       |           |           |           |
//       | valid_in  |           | valid_out |
//    P  |---------->|     S     |---------->| C
//       |           |           |           |
//       | data_in   |           | data_out  |
//       |---------->|           |---------->|
//   -----           -------------           -----

// OPT - 0 : Break on valid, data and ready, inmux
// OPT - 1 : Break on valid and data
// OPT - 2 : Break on only ready
// OPT - 3 : Break on valid, data and ready, outmux
// OPT - 4 : Break on valid, data and ready, outmux optimized (OPT - 3 and OPT - 4 are almost same) 
// OPT - 5 : Break on valid, data and ready, 50% BW
// OPT - 6 : Pass through

    if(OPT == 0) begin
      // Classic single-entry skid buffer

      logic [DW-1:0] skid_data_q;
      logic skid_valid_in;
      logic skid_valid_q;
      logic set_skid_valid;
      logic valid_out_in;
      logic data_en;

      // Skid condition: incoming valid, output not ready, no current skid data
      assign set_skid_valid = ~skid_valid_q 
                              & valid_in 
                              & (valid_out 
                              & ~ready_in);

      // valid_out high if input is valid, or we have skid data, or output is blocked
      assign valid_out_in = valid_in 
                            | skid_valid_q 
                            | (valid_out & ~ready_in);

      // Enable data flop to output only if output is not blocked
      assign data_en = (valid_in | skid_valid_q) 
                       & ~(valid_out & ~ready_in);

      // Track whether we need to hold skid data
      assign skid_valid_in = set_skid_valid 
                             | (skid_valid_q 
                               & ~ready_in);

      // Register control logic
      always_ff@(posedge clk or negedge rstb) begin
        if(~rstb) begin
          skid_valid_q <= 1'b0;
          valid_out <= 1'b0;
        end
        else begin
          skid_valid_q <= skid_valid_in;
          valid_out <= valid_out_in;
        end
      end

      // Capture skid data if needed
      always_ff@(posedge clk) begin
        if(set_skid_valid)
          skid_data_q <= data_in;
      end

      // Output data selection: skid buffer has priority
      always_ff@(posedge clk) begin
        if(data_en)
          data_out <= skid_valid_q ? skid_data_q 
                                     : data_in;
      end

      // Input ready only if skid buffer is empty
      assign ready_out = ~skid_valid_q;

    end else if(OPT == 1) begin
      // Minimal break - break only valid/data

      logic valid_out_in;
      logic data_en;

      // Keep valid high if output is blocked
      assign valid_out_in = valid_in 
                            | (valid_out 
                               & ~ready_in);

      // Ready only if output is not blocked
      assign ready_out = ~(valid_out 
                           & ~ready_in);

      // Accept data when valid and ready
      assign data_en = valid_in 
                       & ready_out;

      always_ff@(posedge clk or negedge rstb) begin
        if(~rstb)
          valid_out <= 1'b0;
        else
          valid_out <= valid_out_in;
      end

      always_ff@(posedge clk) begin
        if(data_en)
          data_out <= data_in;
      end

    end else if(OPT == 2) begin 
      // Break only ready

      logic skid_valid_in;
      logic set_skid_valid;
      logic [DW-1:0] skid_data_q;
      logic skid_valid_q;

      // Capture skid when output stalls during valid
      assign set_skid_valid = ~skid_valid_q 
                              & valid_in 
                              & valid_out 
                              & ~ready_in;

      // Hold skid data until output is ready
      assign skid_valid_in = set_skid_valid 
                            | (skid_valid_q 
                               & ~ready_in);

      // valid_out high when either input or skid data valid
      assign valid_out = valid_in 
                        | skid_valid_q;

      // Output data - skid takes priority
      assign data_out = skid_valid_q ? skid_data_q 
                                      : data_in;

      always_ff@(posedge clk or negedge rstb) begin
        if(~rstb)
          skid_valid_q <= 1'b0;
        else
          skid_valid_q <= skid_valid_in;
      end

      always_ff@(posedge clk) begin
        if(set_skid_valid)
          skid_data_q <= data_in;
      end

      // Input ready when no skid data pending
      assign ready_out = ~skid_valid_q;

    end else if(OPT == 3) begin
      // Dual-entry circular buffer (2-deep FIFO)

      logic wr_ptr_q;
      logic rd_ptr_q;
      logic update_wr_ptr;
      logic update_rd_ptr;      
      logic [1:0] full;
      logic [1:0] [DW-1:0] data_buf;

      // Write and read pointer update enables
      assign update_wr_ptr = valid_in 
                            & ready_out;
	
      assign update_rd_ptr = valid_out 
                            & ready_in;

      for(genvar i=0; i<2; i=i+1) begin
        logic data_en;
        logic update_full;

        // Write if slot is empty and pointer matches
        assign data_en = valid_in 
                          & ~full[i] 
                          & (wr_ptr_q == i);

        // Full update logic: set if writing, clear if read
        assign update_full = data_en 
	                     | (full[i] 
                                & ~(ready_in & (rd_ptr_q == i)));

        // Write data to buffer
        always_ff@(posedge clk) begin
          if(data_en)
            data_buf[i] <= data_in;
        end

        // Update full bit
        always_ff@(posedge clk or negedge rstb) begin
          if(~rstb)
            full[i] <= 1'b0;
          else
            full[i] <= update_full;
        end
      end

      // Pointer update logic
      always_ff@(posedge clk or negedge rstb) begin
        if(~rstb)
          wr_ptr_q <= 1'b0;
        else
          wr_ptr_q <= wr_ptr_q ^ update_wr_ptr;
      end

      always_ff@(posedge clk or negedge rstb) begin
        if(~rstb)
          rd_ptr_q <= 1'b0;
        else
          rd_ptr_q <= rd_ptr_q ^ update_rd_ptr;
      end

      // Data output and handshake
      assign data_out = data_buf[rd_ptr_q];
      assign ready_out = ~(&full);
      assign valid_out = |full;

    end else if(OPT == 4) begin
      // Optimized dual-entry FIFO (2-deep), using 1-bit pointers and single full flag

      logic full;
      logic wr_ptr_q;
      logic rd_ptr_q;
      logic wr_rd_ptr_diff;
      logic almost_full;
      logic full_update;
      logic update_wr_ptr;
      logic update_rd_ptr;
      logic [1:0] [DW-1:0] data_buf;

      // Write and read enable logic
      assign update_wr_ptr = valid_in 
                            & ready_out;

      assign update_rd_ptr = valid_out 
                            & ready_in;

      // Pointer difference: indicates whether FIFO is empty
      assign wr_rd_ptr_diff = wr_ptr_q ^ rd_ptr_q;

      // If we write into the last available slot, almost full becomes true
      assign almost_full = wr_rd_ptr_diff 
                           & update_wr_ptr 
                           & ~full;

      // Update full: set when almost full, clear on read
      assign full_update = almost_full
                           | (full 
                             & ~ready_in);

      // Pointer update
      always_ff@(posedge clk or negedge rstb) begin
        if(~rstb)
          wr_ptr_q <= 1'b0;
        else
          wr_ptr_q <= wr_ptr_q ^ update_wr_ptr;
      end

      always_ff@(posedge clk or negedge rstb) begin
        if(~rstb)
          rd_ptr_q <= 1'b0;
        else
          rd_ptr_q <= rd_ptr_q ^ update_rd_ptr;
      end

      always_ff@(posedge clk or negedge rstb) begin
        if(~rstb)
          full <= 1'b0;
        else
          full <= full_update;
      end

      for(genvar i=0; i<2; i=i+1) begin
        logic data_en;

        assign data_en = (wr_ptr_q == i) 
                         & update_wr_ptr;

        always_ff@(posedge clk) begin
          if(data_en)
            data_buf[i] <= data_in;
        end
      end

      // Output logic
      assign data_out = data_buf[rd_ptr_q];
 
      assign valid_out = wr_rd_ptr_diff 
                         | full;

      assign ready_out = ~full;

    end else if(OPT == 5) begin
      // 1-element buffer, 50% bandwidth, break on all signals

      logic full;
      logic update;
      logic data_en;

      // Write only if not full
      assign data_en = ~full 
                       & valid_in;

      // Full is set on write, cleared on read
      assign update = data_en 
                     | (full 
                        & ~ready_in); 

      always_ff@(posedge clk or negedge rstb) begin
        if(~rstb)
          full <= 1'b0;
        else
          full <= update;
      end

      always_ff@(posedge clk) begin
        if(data_en)
          data_out <= data_in;
      end

      assign valid_out = full;
      assign ready_out = ~full;

    end else begin
      // OPT == 6: Pass-through mode, no buffering
      assign data_out = data_in;
      assign valid_out = valid_in;
      assign ready_out = ready_in;
    end

    // VCD dump for waveform analysis
    initial begin
      $dumpfile("dump.vcd");
      $dumpvars(1, skid);
    end

endmodule
