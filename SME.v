module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output reg match;
output  [4:0] match_index;
output reg valid;
// reg match;
// reg [4:0] match_index_R;
// reg valid;
parameter IDEL_MA = 4'd0, matching_MA = 4'd1, lambdPattern = 4'd2, starPattern = 4'd3, dollar = 4'd4, lambdCPR = 4'd5, UNMATCH = 4'd6;


reg isstring_R, ispattern_R, det_ispattern_R;
reg [7:0] r_string [31:0];
reg [7:0] r_pattern [7:0];
integer i;
reg [5:0] maxString, r_String_cnt;
reg [3:0] maxPattern, r_Pattern_cnt;
reg [3:0] r_SM_matching_MA;
reg [4:0] match_index_R;


assign match_index = match_index_R - maxString[4:0];



always@(posedge clk) 
begin
if(reset)begin
	isstring_R <= 0;
	ispattern_R <= 0; 
	det_ispattern_R <= 0;
	maxString <= 0; 
	r_String_cnt <= 0;
	maxPattern <= 0; 
	r_Pattern_cnt <= 0;
	r_SM_matching_MA <= 0;
	match_index_R <= 0;
	match <= 0;
	valid <= 0;
		
end
else begin
	isstring_R <= isstring;
	ispattern_R <= ispattern;                                           
	det_ispattern_R <= ispattern_R & !ispattern;                        
	if(isstring) begin                                                  
		r_string[31] <= chardata;                                       
		for (i=31; i>=1; i=i-1) begin                                   
			r_string[i-1] <= r_string[i];
		end
		if(!isstring_R && isstring)begin
			maxString <= 0;
		end
		else begin
			maxString <= maxString + 1;
		end
	end
	if(isstring_R && !isstring)begin
		r_String_cnt <= 6'd31 - maxString;
		maxString <= 6'd31 - maxString;
	end
	if(ispattern) begin
		r_pattern[7] <= chardata;
		for (i=7; i>=1; i=i-1) begin
			r_pattern[i-1] <= r_pattern[i];
		end
		if(!ispattern_R && ispattern)begin
			maxPattern <= 0;
		end
		else begin
			maxPattern <= maxPattern + 1;
		end
	end	
	if(ispattern_R && !ispattern)begin
		r_Pattern_cnt <= 4'd7 - maxPattern;
		maxPattern <= 4'd7 - maxPattern;
	end
	
	
	
		
	
	
	case (r_SM_matching_MA)
		IDEL_MA : 
			begin
				if(det_ispattern_R)begin
					match_index_R <= r_String_cnt;
					if(r_pattern[r_Pattern_cnt] == 94) //^^^^^^^^^^
						begin
							r_SM_matching_MA <= lambdPattern;
						end
					
					else if(r_pattern[r_Pattern_cnt] == 42)//*************
						begin
							r_SM_matching_MA <= starPattern;
							r_Pattern_cnt <= r_Pattern_cnt + 1;
							r_String_cnt <= r_String_cnt + 1;
						end
					else if(r_pattern[r_Pattern_cnt] == r_string[r_String_cnt] || r_pattern[r_Pattern_cnt] == 46) // .......
						begin
							r_SM_matching_MA <= matching_MA;
							r_Pattern_cnt <= r_Pattern_cnt + 1;
							r_String_cnt <= r_String_cnt + 1;
						end
					
					else
						begin
							r_SM_matching_MA <= UNMATCH;
							
						end
				end
			end
			
		matching_MA : 
			begin
				
				
				if(r_pattern[r_Pattern_cnt] == 42)// * 
					begin
						r_SM_matching_MA <= starPattern;
						r_Pattern_cnt <= r_Pattern_cnt + 1;
						r_String_cnt <= r_String_cnt + 1;
					end
					
				else if(r_pattern[r_Pattern_cnt] == 36)// $
					begin
						r_SM_matching_MA <= dollar;
					end
				else if(r_pattern[r_Pattern_cnt] == r_string[r_String_cnt] | r_pattern[r_Pattern_cnt] == 46) // .......
					begin
						r_SM_matching_MA <= matching_MA;
						r_Pattern_cnt <= r_Pattern_cnt + 1;
						r_String_cnt <= r_String_cnt + 1;
						if(r_String_cnt == 6'd31 && r_Pattern_cnt == 6)begin
							r_String_cnt <= 6'd31;
						end
						
					end
				
				else
					begin
						r_SM_matching_MA <= UNMATCH;
						r_String_cnt <= match_index_R + 1;
						r_Pattern_cnt <= maxPattern;
					end
			end	
			
		lambdPattern : 
			begin
				
				if(r_string[r_String_cnt] == 32)
					begin
						r_SM_matching_MA <= lambdCPR;
						r_Pattern_cnt <= r_Pattern_cnt + 1;
						r_String_cnt <= r_String_cnt + 1;
					
					end
				else if(r_String_cnt == maxString)
					begin
						r_SM_matching_MA <= lambdCPR;
						r_Pattern_cnt <= r_Pattern_cnt + 1;
					
					end
				else 
					begin
						r_SM_matching_MA <= lambdPattern;
						r_String_cnt <= r_String_cnt + 1;
					
					end
				
			end	
		lambdCPR : 
			begin
				match_index_R <= r_String_cnt;
				if(r_pattern[r_Pattern_cnt] == r_string[r_String_cnt] || r_pattern[r_Pattern_cnt] == 46)begin
					r_SM_matching_MA <= matching_MA;
					r_Pattern_cnt <= r_Pattern_cnt + 1;
					r_String_cnt <= r_String_cnt + 1;
				end
				else begin
					r_SM_matching_MA <= lambdPattern;
					r_Pattern_cnt <= r_Pattern_cnt - 1;
					r_String_cnt <= r_String_cnt + 1;
				end
				
			end
		
		
		starPattern :
			begin
				
				if(r_pattern[r_Pattern_cnt] == r_string[r_String_cnt])
					begin
						r_SM_matching_MA <= matching_MA;
					end
				else if(r_pattern[r_Pattern_cnt] != r_string[r_String_cnt])
					begin
						r_SM_matching_MA <= starPattern;
						r_String_cnt <= r_String_cnt + 1;
					end
				else if(r_pattern[r_Pattern_cnt] == 46 || r_pattern[r_Pattern_cnt] == 42)// ... ***
					begin
						r_SM_matching_MA <= starPattern;
						r_Pattern_cnt <= r_Pattern_cnt + 1;
					end
				
				
			end
			
		dollar :
			begin
				
				if(r_string[r_String_cnt] == 32 || r_String_cnt == 6'd31)
					begin
						r_Pattern_cnt <= r_Pattern_cnt + 1;
					end
				else
					begin
						r_SM_matching_MA <= UNMATCH;
						r_Pattern_cnt <= maxPattern;
						r_String_cnt <= match_index_R + 1;
					end
			end
		UNMATCH : begin
			if(r_pattern[r_Pattern_cnt] == 94) //^^^^^^^^^^
				begin
					r_SM_matching_MA <= lambdPattern;
				end
					
			else if(r_pattern[r_Pattern_cnt] == r_string[r_String_cnt] | r_pattern[r_Pattern_cnt] == 46) // .......
				begin
					r_SM_matching_MA <= matching_MA;
					r_String_cnt <= r_String_cnt + 1;
					r_Pattern_cnt <= r_Pattern_cnt + 1;
					match_index_R <= r_String_cnt;
				end
			else
				begin
					r_SM_matching_MA <= UNMATCH;                                             
					r_String_cnt <= r_String_cnt + 1;
					
				end
		end
			
		default :
			begin
				r_SM_matching_MA <= IDEL_MA;
			end
	endcase

	match <= 0;
	valid <= 0;
	if(r_Pattern_cnt[3])
		begin
			match <= 1;
			valid <= 1;
			r_SM_matching_MA <= IDEL_MA;
			r_Pattern_cnt <= 0;
			r_String_cnt <= maxString;
			maxPattern <= 0;
		end
	else if(!r_Pattern_cnt[3] && r_String_cnt[5])
		begin
			match <= 0;
			valid <= 1;
			r_SM_matching_MA <= IDEL_MA;
			r_Pattern_cnt <= 0;
			r_String_cnt <= maxString;
			maxPattern <= 0;
		end

end
end
endmodule 
