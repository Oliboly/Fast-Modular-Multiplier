`timescale 1ns / 1ps

module tb_mod_multiplier();

// �ź�����
reg clk;                 // ϵͳʱ�ӣ����� 10ns��
reg rst_n;               // �첽�͵�ƽ��λ�ź�
reg en;                  // ����ʹ���źţ�����Ч��
reg [11:0] a;            // ������� a��12 λ�޷��ţ�
reg [11:0] b;            // ������� b��12 λ�޷��ţ�
wire busy;               // ����ģ��æ״ָ̬ʾ
wire done;               // ����ģ������ź�
wire [11:0] r;           // ����ģ����������

// ʵ��������ģ��
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

// ʱ�������߼������� 10ns��
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// ��λ��ʼ��
initial begin
    rst_n = 0;
    #20;
    rst_n = 1;
    #10;
end

// ���Խ��ͳ��
integer total_tests = 0;
integer error_count = 0;
integer start_time, end_time;

// ========================
// ���β�������
// ========================
task automatic single_test;
    input [11:0] ta;
    input [11:0] tb;
    input [11:0] expected;
    integer result;
    begin
        en = 0;
        @(negedge clk);
        
        // ʩ�Ӳ��Լ���
        en = 1;
        a = ta;
        b = tb;
        
        @(negedge clk);
        en = 0;
        
        // �ȴ�������
        wait(done);
        
        // �����֤
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
// �������ܲ���
// ========================
task automatic basic_tests;
    begin
        $display("===== �������ܲ��Կ�ʼ =====");
        
        // ��������1: ���������
        single_test(0, 0, 0);
        
        // ��������2: ��С����������
        single_test(1, 1, 1);
        
        // ��������3: �߽�ֵ����
        single_test(3328, 3328, 1);  // (-1)*(-1) mod 3329 = 1
        
        // ��������4: �����������
        single_test(3000, 3000, 1713);
        
        // ��������5: �������
        single_test(4095, 4095, 852); // 12λ���ֵ����
        
        $display("===== �������ܲ������ =====");
        $display("����������: %0d, ������: %0d", total_tests, error_count);
    end
endtask

// ========================
// �������
// ========================
task automatic random_tests;
    input integer num_tests;
    integer i, ta, tb, expected;
    begin
        $display("===== ������Կ�ʼ (%0d��) =====", num_tests);
        
        for (i = 0; i < num_tests; i = i + 1) begin
            // ���������������
            ta = $urandom_range(0, 4095);
            tb = $urandom_range(0, 4095);
            expected = (ta * tb) % 3329;
            
            single_test(ta, tb, expected);
            
            // ÿ100�β��Դ�ӡ����
            if (i % 100 == 0) begin
                $display("����� %0d ���������...", i);
            end
        end
        
        $display("===== ���������� =====");
        $display("����������: %0d, ������: %0d", num_tests, error_count);
    end
endtask

// ========================
// ȫ��������
// ========================
task automatic full_traversal_test;
    integer i, j, expected;
    begin
        $display("===== ȫ�������Կ�ʼ (0-3328) =====");
        start_time = $time;
        
        for (i = 0; i < 3329; i = i + 1) begin
            for (j = 0; j < 3329; j = j + 1) begin
                expected = (i * j) % 3329;
                single_test(i, j, expected);
                
                // ÿ10000�β��Դ�ӡ����
                if ((i*3329 + j) % 10000 == 0) begin
                    $display("����: %0d/%0d (%.1f%%)", 
                             i*3329+j, 3329*3329, 
                             (real'(i*3329+j)*100.0/(3329*3329)));
                end
            end
        end
        
        end_time = $time;
        $display("===== ȫ����������� =====");
        $display("����������: %0d, ������: %0d", 3329*3329, error_count);
        $display("�ܺ�ʱ: %0.2f ms", (end_time - start_time)/1000000.0);
    end
endtask

// ========================
// ���ֱ������� (0-100)
// ========================
task automatic partial_traversal_test;
    integer i, j, expected;
    begin
        $display("===== ���ֱ������Կ�ʼ (0-100) =====");
        start_time = $time;
        
        for (i = 0; i <= 100; i = i + 1) begin
            for (j = 0; j <= 100; j = j + 1) begin
                expected = (i * j) % 3329;
                single_test(i, j, expected);
            end
        end
        
        end_time = $time;
        $display("===== ���ֱ���������� =====");
        $display("����������: %0d, ������: %0d", 101*101, error_count);
        $display("��ʱ: %0.2f ms", (end_time - start_time)/1000000.0);
    end
endtask

// ========================
// ����������
// ========================
initial begin
    // �ȴ���λ���
    #30;
    
    // ִ�л�������
   // basic_tests();
    
    // ִ��������� (1000��)
   // random_tests(1000);
    
    // ִ�в��ֱ������� (0-100)
    //partial_traversal_test();
    
    // ��ѡ��ִ��ȫ�������� (0-3328)
    // ע�⣺ȫ�������Ժ�ʱ�ܳ���Լ��Сʱ����ͨ��ֻ��������֤ʱʹ��
     full_traversal_test();
    
    // �����ܽᱨ��
    $display("\n===== �����ܽ� =====");
    $display("�ܲ���������: %0d", total_tests);
    $display("�ܴ�����: %0d", error_count);
    $display("����ͨ����: %.2f%%", (real'(total_tests - error_count)*100.0/total_tests));
    
    if (error_count == 0) begin
        $display("*** ���в���ͨ�� ***");
    end else begin
        $display("!!! ���ִ���������� !!!");
    end
    
//    #100 $finish;
end

endmodule