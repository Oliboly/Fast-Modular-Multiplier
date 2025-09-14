// -----------------------------------------------------------------------------
// 模块名称: mod_multiplier
// 功能描述: 基于巴雷特约减法的12位流水线快速模乘器，支持在固定周期内计算 (a*b) mod q（q=3329）
// 关键设计:
//   - 使用5级流水线结构，每阶段由counter控制
//   - 采用巴雷特约减法优化模运算（避免除法）
//   - 输入使能后，经过5个周期输出稳定结果
// -----------------------------------------------------------------------------
module mod_multiplier (
    input        clk,     // 系统时钟
    input        rst_n,   // 异步低电平复位
    input        en,      // 计算使能信号（高有效）
    input  [11:0] a,      // 输入乘数a（12位无符号）
    input  [11:0] b,      // 输入乘数b（12位无符号）
    output reg   busy,    // 忙状态指示（高表示计算中）
    output reg   done,    // 完成信号（高脉冲表示结果有效）
    output reg [11:0] r   // 计算结果输出 (a*b mod 3329)
);

// --------------------------------------
// 参数定义
// --------------------------------------
localparam Q  = 12'd3329;  // 固定模数
localparam MU = 14'd5039;  // 巴雷特参数：MU = floor(2^24 / Q) = 16777216/3329 ≈ 5039

// --------------------------------------
// 内部寄存器定义
// --------------------------------------
reg [11:0] a_reg, b_reg;  // 输入锁存寄存器（保存当前计算的a/b值）
reg [23:0] x;              // Stage1: 存储a*b的中间结果（24位）
reg [37:0] q1;             // Stage2: 存储 x*MU的完整结果（38位）
reg [13:0] q2;             // Stage3: 存储商估计值（14位，用于计算余数）
reg [23:0] r_temp;         // Stage4: 存储 x - q2*Q 的余数（24位）
reg [2:0]  counter;        // 流水线阶段计数器（0-4对应5个阶段）

// --------------------------------------
// 主状态机逻辑（时钟上升沿触发）
// --------------------------------------
always @(posedge clk or negedge rst_n)
    begin
    if (!rst_n) begin // 异步复位初始化
        busy    <= 0;
        done    <= 0;
        r       <= 0;
        counter <= 0;
        a_reg   <= 0;
        b_reg   <= 0;
        x       <= 0;
        q1      <= 0;
        q2      <= 0;
        r_temp  <= 0;end 
     else begin
        done <= 0; // 默认done为0，仅在完成阶段置1
        
        // 检测使能信号且空闲时启动计算
        if (en && !busy) begin      //使能且空闲
            a_reg <= a;    // 锁存输入a
            b_reg <= b;    // 锁存输入b
            busy  <= 1;    // 进入忙状态
            counter <= 0;  // 重置阶段计数器
        end 
        // 忙状态下分阶段计算
        else if (busy) begin
            case (counter)
                // Stage 1: 计算x = a * b（24位乘法）
                0: begin
                    x <= a_reg * b_reg;
                    counter <= counter + 1;
                end
                
                // Stage 2: 计算q1 = x * MU 
                1: begin
                    q1 <= x * MU; 
                    counter <= counter + 1;
                end
                
                // Stage 3: 计算 q2=q1>>24（14位，用于计算余数）
                2: begin
                    q2 <= q1 >> 14; //取高14位，即右移14位
                    counter <= counter + 1;
                end
                
                // Stage 4: 计算余数 r_temp = x - q2*Q
                3: begin
                    r_temp <= x - q2*Q;
                    counter <= counter + 1;
                end
                
                // Stage 5: 调整余数至[0, Q-1]范围
                4: begin
                    if (r_temp >= Q) begin //如果余数大于Q
                        r <= r_temp - Q;end 
                          else if (r_temp[23])begin // 检查符号位（负数）
                        r <= r_temp + Q;end 
                          else begin             
                        r <= r_temp[11:0];end
                                
                    busy   <= 0;    // 清除忙状态
                    done   <= 1;    // 输出完成脉冲
                    counter <= 0;   // 重置计数器
                end
                
                default: counter <= 0;
            endcase
        end
    end
end

endmodule