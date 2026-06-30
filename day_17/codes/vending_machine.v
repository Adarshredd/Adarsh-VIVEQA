module vending_machine(clk,rst,coin,D,C);
input clk,rst;
input [1:0]coin;
output reg D,C;

parameter IDLE=3'b000,
		  S1=3'b001,
		  S2=3'b010,
		  S3=3'b011,
		  S4=3'b100;
		  
reg [2:0]state,next_state;

always@(posedge clk)begin
	if(rst)
	  state<=IDLE;
	else 
	  state<=next_state;
end

always@(*)begin
    D=1'b0;C=1'b0;
	case(state)
	IDLE: if (coin==2'b01)begin
	        next_state=S1;
			D=1'b0;C=1'b0;
	      end else if (coin==2'b10)begin
		    next_state=S2;
			D=1'b0;C=1'b0;
		  end else next_state=IDLE;

	S1: if (coin==2'b01)begin
	        next_state=S2;
			D=1'b0;C=1'b0;
	      end else if (coin==2'b10)begin
		    next_state=S3;
			D=1'b0;C=1'b0;
		  end else next_state=S1;

	S2: if (coin==2'b01)begin
	        next_state=S3;
			D=1'b0;C=1'b0;
	      end else if (coin==2'b10)begin
		    next_state=S4;
			D=1'b0;C=1'b0;
		  end else next_state=S2;
		  
	S3: begin 
	      next_state=IDLE;
          D=1'b1;C=1'b0;
        end
	
	S4: begin 
	      next_state=IDLE;
          D=1'b1;C=1'b1;
        end
	default: begin 
	      D=1'b0;C=1'b0;
	      next_state=IDLE;
	     end
    endcase
end
endmodule
