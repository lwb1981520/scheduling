%这个类保存一次实验中所有的参数和产生中间使用的分布
%并完成一次实验


classdef FrpLab
    
    properties
        
        %输入参数
            I;
            J;
            zipf;
            %所有i,j的总需求数
            total;

        
        
            wsat;
            wloc;
        
        %需生成的参数
            %p_i*p_j*total是那个区域的需求量
            p_i;
            p_j;

            %每个i,j的平均需求量，Di和Dij略去因这里是均值，使用时用poiss的cdf即可
            Mij;
            Mi;
        
        %ssp迭代参数
            %目标流量,也相当于总的使用资源量
            TAR_traf;
            %求解每次增量
            flow_inc;
            %frp的迭代次数
            TAR_traf2frp;
            
            
        
        
        
        
    end
    
methods(Static)
    
    function test()
       
           afrp = FrpLab();
           
           afrp.I = 4;
           afrp.J = 8;
           %总共请求是total
           afrp.total = 100;
           %可用资源是TAR_traf
           afrp.TAR_traf = 150;
           
           
           afrp = afrp.setup();
           
           
        
           %[sLi sLij sReven] = afrp.solveSSP()
            
           
           %[mLi mLij mReven] = afrp.solveMean()
           
           
        
    end
    
    %use poisscdf
    function val = funcEMin(x_mean,c)
       
        val = 0;
        
        k=0;
        
        while(k<=c)
            %pr(x>=k) = 1 - pr(x<=k) = 1 - cdf_x(k)
            val = val + 1 - poisscdf(k,x_mean);
            k = k+1;
        end
        
    end
    
    
end

methods
    
     function self=FrpLab()
        
           self.zipf = 0.6;
           self.I = 16;
           self.J = 4;
           
           self.total = 100;
           
           self.TAR_traf = 50;
           self.TAR_traf2frp = self.TAR_traf;
           
           self.wsat = 1;
           self.wloc = 1;
           
           self.flow_inc = 1;
         
     end
     
     %产生dij和di
     function obj=setup(self)
         
         
         %根据zipf公式计算p_i 
        is = 1:self.I;
        ie_list = is.^(-self.zipf);
        H = sum(ie_list);
        self.p_i = ie_list/H;
         
         %平均化的p_j
         self.p_j = ones(self.J,1)/self.J;
         
         %产生Mi和Mij,即各个区域的均值
         
            %I行J列的值
         prop_ij = self.p_i'*self.p_j';
         
         self.Mij = prop_ij * self.total;
         self.Mi = self.p_i * self.total;

         
         
         obj=self;
         
     end
     
     
     
    function arevenue = getRevenue(self,Li,Lij)
        
        arevenue = 0;
        
         for i = 1:self.I;
             
             %Mij是Dij的均值，故变量名称相区分
             
             
             arevenue = arevenue + self.wsat*FrpLab.funcEMin(self.Mi(i),Li(i)); %(1-poisscdf(Li(i),self.Mi(i)));

             
             for j = 1:self.J
                 

                arevenue = arevenue + self.wloc*FrpLab.funcEMin(self.Mij(i,j),Lij(i,j));

                 
             end
         end
        
    end
      
    
     %用图方法解决问题
     %解决的结果放在当前对象中的Lij和Li
     function [Li Lij arevenue collector] = solveSSP(self)
         
         %创建graph, 并运行ssp解法
         gm = GraphMaker.solve(self);
         
         %gm.printTraf(gm.G);
         %self.Mi
         %self.Mij
         %从图中转换得到结果，赋值到Lij和Li上
         Li = zeros(1,self.I);
         Lij = zeros(self.I,self.J);
         

         
         for i = 1:self.I;
             
             %Mij是Dij的均值，故变量名称相区分
             
             Li(i) = gm.getTrafValue(gm.Eg([3 i],[4 1],-1,0,0));
             
             for j = 1:self.J
                 
                Lij(i,j) = gm.getTrafValue(gm.Eg([2 j],[3 i],-1,0,0));
                 
             end
         end
         
         arevenue = self.getRevenue(Li,Lij);
         
         collector = gm.collector;
     end
     
     
     %用均值法解决问题
     
     function [Li Lij arevenue] = solveMean(self)
         
         %创建graph, 并运行ssp解法
         %gm = GraphMaker.solve(self);
         
         %从图中转换得到结果，赋值到Lij和Li上
         Li = zeros(1,self.I);
         Lij = zeros(self.I,self.J);

         
         sum_Mi = sum(self.Mi);
         
         for i = 1:self.I;
             
             %Mij是Dij的均值，故变量名称相区分
             
            Li(i) = self.TAR_traf*self.Mi(i)/sum_Mi;
             for j = 1:self.J
                 

                Lij(i,j) = self.TAR_traf*self.Mij(i,j)/sum_Mi;
                 
             end
         end
         
         arevenue = self.getRevenue(Li,Lij);
         
         
     end
     
     function y=cdfi(self,i,x)
        
         y = poisscdf(x,self.Mi(i));
         
     end
     
     function x=cdfi_1(self,i,y)
        
         x = poissinv(y,self.Mi(i));
         
     end
     
     
     function y=cdfij(self,i,j,x)
        
         y = poisscdf(x,self.Mij(i,j));
         
     end
     
     function x=cdfij_1(self,i,j,y)
        x = poissinv(y,self.Mij(i,j));
     end
     
     function [Li Lij arevenue kp] = solveFrp(self)
     
         
         H = DiscFunc();
         
         %get pre-caculated cdf_i and cdf_ij         
            %donothing: calculated in real time
         %计时函数
%          ct = 0;
%          tic;
%          
%          ct = toc
%          tic;
         
         for i=1:self.I
            
             Xi_sum = 0;
             for j=1:self.J
                
                 Xi_sum = Xi_sum + poissinv(0.9999999999,self.Mij(i,j));
            
             end
             
             G(i) = DiscFunc();
             
             G(i) = G(i).addxy(0,Xi_sum);
             G(i) = G(i).setBoundX([ 1.0000001 intmax], 0);
             G(i) = G(i).setBoundY([ Xi_sum  intmax], 0);
             
             hp(i) = DiscFunc();
             
             hp(i) = hp(i).addxy(0,self.wsat+self.wloc);
             hp(i) = hp(i).setBoundX([Xi_sum intmax], 0);
             hp(i) = hp(i).setBoundY([Xi_sum intmax],0);
             
         end
         
        
         
         U = self.TAR_traf;
         IJ = self.I*self.J;
         K = self.TAR_traf2frp;
         
         if(K < 10)
            display(sprintf('!!!!!!!!!!!!!!!WARNING: K=%d < 10',K)); 
         end
         
         k2 = 0;
         
         appro_1 = 1-1e-10;
         
         kp = -1;
         
         for k=0:K
                
             v =   1.0 - double(k)/double(K);

             if (v <0 || v > 1)
                throw(MException('frp:solve_err','v not in [0 1]')); 
             end
             
             if ( mod(k*100,K) == 0)
                %display(sprintf('%.1f%%: %d %d',v*100,k,K)); 
             end
             
             for i=1:self.I
                 
                 L_i = 0;
                 for j=1:self.J

                     v_sub = 1-v;
                     
                     if(v_sub - appro_1 >= 0)
                         %为啥？因为cdfij_1如果给1，可能返回inf
                         %如果改了v，则后面的addxy会使得没有x=0的y，后面计算会出问题
                        v_sub = appro_1;
                     end
                     
                     L_i = L_i + self.cdfij_1(i,j,v_sub);
                     
                  
                 end
                 
                 G(i) = G(i).addxy(v,L_i);
                 
                 s = self.wsat * (1- self.cdfi(i,L_i)) + self.wloc * G(i).getx(L_i);
                 
                 
                 hp(i) = hp(i).addxy(L_i,s);
                 
                 %[L_i v s]
             end
             
             %开始计算H，注意需要寻找k及以前的值
             
             while(k2 <= k)
                 
                 s=double(self.wsat + self.wloc)*double(K-k2)/double(K);

                 Up = 0;

                 is_done = 1;

                 for i=1:self.I

                     if(~hp(i).hasY(s))
                        %这次k2迭代退出，且k2不增加
                        %is_done =0 表示这次Up没有计算完毕
                        is_done = 0;
                        break; 
                     end
                     
                     if(isnan(hp(i).getx(s)))
                        throw(MException('frp:solve_err',sprintf('hp %f get %f == inf',i,s))); 
                     end
                     
                     Up = Up + hp(i).getx(s);
                 end

             
                 if(~is_done)
                    %这次不计算了
                    break; 
                 end

                 k2 = k2+1;
                 
                 if(isnan(Up))
                 	display(sprintf('WARNING: for H(%f) = NaN',s));
                     
                 end
                 H = H.addxy(s,Up);
                 
                 %[k2 k s Up]

                 %如果达到目标值，则退出整个循环
                 if(Up >= U)
                     %下次迭代才退出
                    kp = k + 1;
                    break; 
                 end
                 
             end
             
            if(k == kp)
                break; 
            end
             
         end
         
         
         %输出结果
         kp = kp -1;
         
         Li = zeros(1,self.I);
         Lij = zeros(self.I,self.J);
         
        s = H.getx(U);
         
        for i=1:self.I
             

             
         	Li(i) = hp(i).getx(s);
             
            
         
            %display(sprintf('DEBUG_L: %f\t%f',Li(i),sum(Lij(i,:))));
        end
        
        %检验结果是否符合即sum(Li) = U
       
        Li = Li * U /sum(Li);
        
         
         for i=1:self.I
         	g_sub = 1-G(i).getx(Li(i));
            
            if(g_sub - appro_1 >= 0)
                %原因同上，cdf-1不能给1，可能返回inf
               g_sub = appro_1; 
            end
            
            for j=1:self.J
                Lij(i,j) =  self.cdfij_1(i,j,g_sub);
            end
            
            
            sum_Lij = sum(Lij(i,:));
            
            if(sum_Lij>0)
                Lij(i,:) = Lij(i,:) * Li(i) / sum(Lij(i,:));
            else
                Lij(i,:) = Li(i)/self.J;
            end
            
            %display(sprintf('DEBUG_L: %f\t%f',Li(i),sum(Lij(i,:))));
            
         end
         
         
         arevenue = self.getRevenue(Li,Lij);

         
     end

end
    
    
    
end

