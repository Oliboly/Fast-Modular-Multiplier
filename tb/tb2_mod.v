`timescale 1ns / 1ps

module tb_mod_multiplier();

// 信号声明
reg clk;                 // 系统时钟（周期 10ns）
reg rst_n;               // 异步低电平复位信号
reg en;                  // 计算使能信号（高有效）
reg [11:0] a;            // 输入乘数 a（12 位无符号）
reg [11:0] b;            // 输入乘数 b（12 位无符号）
wire busy;               // 被测模块忙状态指示
wire done;               // 被测模块完成信号
wire [11:0] r;           // 被测模块计算结果输出

// 实例化被测模块
mod_multiplier dut (
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .a(a),
    .b(b),
    .busy(busy),
    .done(done),
    .r(r)
);

// 时钟生成逻辑（周期 10ns）
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// 复位初始化
initial begin
    rst_n = 0;
    #20;
    rst_n = 1;
    #10;
end

// 测试结果统计
integer total_tests = 0;
integer error_count = 0;
integer start_time, end_time;

// ========================
// 单次测试任务
// ========================
task automatic single_test;
    input [11:0] ta;
    input [11:0] tb;
    input [11:0] expected;
    integer result;
    begin
        en = 0;
        @(negedge clk);
        
        // 施加测试激励
        en = 1;
        a = ta;
        b = tb;
        
        @(negedge clk);
        en = 0;
        
        // 等待计算结果
        wait(done);
        
        // 结果验证
        result = (ta * tb) % 3329;
        total_tests = total_tests + 1;
        
        if (r !== expected) begin
            error_count = error_count + 1;
            $display("[ERROR] a=%4d, b=%4d | Got=%4d, Exp=%4d, Calc=%4d",
                      ta, tb, r, expected, result);
        end
    end
endtask

// ========================
// 基础功能测试
// ========================
task automatic basic_tests;
    begin
        $display("===== 基础功能测试开始 =====");
        
        // 测试用例1: 零输入测试
        single_test(0, 0, 0);
        
        // 测试用例2: 最小正整数测试
        single_test(1, 1, 1);
        
        // 测试用例3: 边界值测试
        single_test(3328, 3328, 1);  // (-1)*(-1) mod 3329 = 1
        
        // 测试用例4: 大数运算测试
        single_test(3000, 3000, 1713);
        
        // 测试用例5: 溢出测试
        single_test(4095, 4095, 852); // 12位最大值测试
        
        $display("===== 基础功能测试完成 =====");
        $display("测试用例数: %0d, 错误数: %0d", total_tests, error_count);
    end
endtask

// ========================
// 随机测试
// ========================
task automatic random_tests;
    input integer num_tests;
    integer i, ta, tb, expected;
    begin
        $display("===== 随机测试开始 (%0d次) =====", num_tests);
        
        for (i = 0; i < num_tests; i = i + 1) begin
            // 生成随机测试用例
            ta = $urandom_range(0, 4095);
            tb = $urandom_range(0, 4095);
            expected = (ta * tb) % 3329;
            
            single_test(ta, tb, expected);
            
            // 每100次测试打印进度
            if (i % 100 == 0) begin
                $display("已完成 %0d 次随机测试...", i);
            end
        end
        
        $display("===== 随机测试完成 =====");
        $display("测试用例数: %0d, 错误数: %0d", num_tests, error_count);
    end
endtask

// ========================
// 全遍历测试
// ========================
task automatic full_traversal_test;
    integer i, j, expected;
    begin
        $display("===== 全遍历测试开始 (0-3328) =====");
        start_time = $time;
        
        for (i = 0; i < 3329; i = i + 1) begin
            for (j = 0; j < 3329; j = j + 1) begin
                expected = (i * j) % 3329;
                single_test(i, j, expected);
                
                // 每10000次测试打印进度
                if ((i*3329 + j) % 10000 == 0) begin
                    $display("进度: %0d/%0d (%.1f%%)", 
                             i*3329+j, 3329*3329, 
                             (real'(i*3329+j)*100.0/(3329*3329)));
                end
            end
        end
        
        end_time = $time;
        $display("===== 全遍历测试完成 =====");
        $display("测试用例数: %0d, 错误数: %0d", 3329*3329, error_count);
        $display("总耗时: %0.2f ms", (end_time - start_time)/1000000.0);
    end
endtask

// ========================
// 部分遍历测试 (0-100)
// ========================
task automatic partial_traversal_test;
    integer i, j, expected;
    begin
        $display("===== 部分遍历测试开始 (0-100) =====");
        start_time = $time;
        
        for (i = 0; i <= 100; i = i + 1) begin
            for (j = 0; j <= 100; j = j + 1) begin
                expected = (i * j) % 3329;
                single_test(i, j, expected);
            end
        end
        
        end_time = $time;
        $display("===== 部分遍历测试完成 =====");
        $display("测试用例数: %0d, 错误数: %0d", 101*101, error_count);
        $display("耗时: %0.2f ms", (end_time - start_time)/1000000.0);
    end
endtask

// ========================
// 主测试流程
// ========================
initial begin
    // 等待复位完成
    #30;
    
    // 执行基础测试
   // basic_tests();
    
    // 执行随机测试 (1000次)
   // random_tests(1000);
    
    // 执行部分遍历测试 (0-100)
    //partial_traversal_test();
    
    // 可选：执行全遍历测试 (0-3328)
    // 注意：全遍历测试耗时很长（约数小时），通常只在最终验证时使用
     full_traversal_test();
    
    // 测试总结报告
    $display("\n===== 测试总结 =====");
    $display("总测试用例数: %0d", total_tests);
    $display("总错误数: %0d", error_count);
    $display("测试通过率: %.2f%%", (real'(total_tests - error_count)*100.0/total_tests));
    
    if (error_count == 0) begin
        $display("*** 所有测试通过 ***");
    end else begin
        $display("!!! 发现错误，请检查设计 !!!");
    end
    
//    #100 $finish;
end

endmodule