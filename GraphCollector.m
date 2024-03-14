
%这个类用于收集
%只要实现collect接口即可

classdef GraphCollector
   
    
    properties
        
        afrp;
        results;
        ridx;
        
    end
    
    
    methods
        
        function self = GraphCollector(tfrp)
            self.ridx = 1;
            self.afrp = tfrp;
            
            resu.Li = zeros(1,tfrp.I);
            resu.Lij = zeros(tfrp.I,tfrp.J);
            resu.U = 0;
            tresults(1) = resu;

            
            self.results = tresults;
            
        end
        
        function resu_ret = getByU(self,aU)
            
            resu_ret = 0;
            
            for i=1:self.ridx
               
                resu = self.results(i);
                
                if(resu.U == aU)
                    resu_ret = resu;
                    break;
                end
                
            end
            
            
            
        end
        
        function obj = collect(self,gm)
            
            tfrp = self.afrp;
            
            resu.Li = zeros(1,tfrp.I);
            resu.Lij = zeros(tfrp.I,tfrp.J);



             for i = 1:tfrp.I;

                 %Mij是Dij的均值，故变量名称相区分

                 resu.Li(i) = gm.getTrafValue(gm.Eg([3 i],[4 1],-1,0,0));

                 for j = 1:tfrp.J

                    resu.Lij(i,j) = gm.getTrafValue(gm.Eg([2 j],[3 i],-1,0,0));

                 end
             end
            
            resu.U = sum(resu.Li);
            
            %放到results中

            self.results(self.ridx) = resu;
            
            self.ridx = self.ridx + 1;
            
            obj = self;
        end
        
    end
    
    
end