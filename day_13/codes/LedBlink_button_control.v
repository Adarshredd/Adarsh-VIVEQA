`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.06.2026 12:49:24
// Design Name: 
// Module Name: LedBlink_button_control
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module LedBlink_button_control(input clk,b_plus,b_minus, output reg led=0);
    wire pulse_plus,pulse_minus;
    reg [2:0]state,next_state;
    reg [26:0]counter=0;
    reg led1=0,led2=0,led3=0,led4=0,led5=0;
    debounce d1(clk,b_plus,pulse_plus);
    debounce d2(clk,b_minus,pulse_minus);
    always @(posedge clk) begin
        state <= next_state;
    end
    always @(posedge clk)begin  
        if(counter==26'd47_999_999 && state == 3'b100)begin
            counter = 26'd0;
	        led1=~led1;
        end 
        else if(counter==26'd23_999_999 && state == 3'b011)begin
            counter = 26'd0;
	        led2=~led2;
        end 
        else if(counter==26'd11_999_999 && state == 3'b010)begin
            counter = 26'd0;
	        led3=~led3;
        end 
        else if(counter==26'd5_999_999 && state == 3'b001)begin
            counter = 26'd0;
	        led4=~led4;
        end 
        else if(counter==26'd2_999_999 && state == 3'b000)begin
            counter = 26'd0;
	        led5=~led5;
        end 
        else
            counter=counter +1;
        end
    always @(*) begin
        case (state)
            3'b000: begin
                    led = led5;
                     if (pulse_plus)begin
                        next_state <= 3'b000;
                    end
                    else if (pulse_minus) begin
                         next_state <= 3'b001;
                    end
                    else  next_state <= 3'b000;
                   end
           3'b001: begin
                    led = led4;
                     if (pulse_plus)begin
                        next_state <= 3'b000;
                    end
                    else if (pulse_minus) begin
                         next_state <= 3'b010;
                    end
                    else  next_state <= 3'b001;
                   end
           3'b010: begin
                    led = led3;
                     if (pulse_plus)begin
                        next_state <= 3'b001;
                    end
                    else if (pulse_minus) begin
                         next_state <= 3'b011;
                    end
                    else  next_state <= 3'b010;
                   end
           3'b011: begin
                     led = led2;
                     if (pulse_plus)begin
                        next_state <= 3'b010;
                    end
                    else if (pulse_minus) begin
                         next_state <= 3'b100;
                    end
                    else  next_state <= 3'b011;
                   end
           3'b100: begin
                     led = led1;
                     if (pulse_plus)begin
                        next_state <= 3'b000;
                    end
                    else if (pulse_minus) begin
                         next_state <= 3'b100;
                    end
                    else  next_state <= 3'b100;
                   end
           default: next_state <= 3'b000;
       endcase
end
    
        
endmodule

module debounce(input clk,button, output pulse);
    reg q1,q2;
    always @(posedge clk) begin
        q1 <= button;
        q2 <= q1;
    end
    assign pulse = q1 & ~q2;
endmodule