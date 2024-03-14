classdef GraphMaker
    %GRAPHMAKE Summary of this class goes here
    %   Detailed explanation goes here
    
    %节点由向量表示，第一个元素是层数，后面的是对应的下标
    
    properties
        
        frp;
        
        %%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%
        %%%原图G，补图Gsup;

        G;
        Gsup;
        
        %表示所有的已有流量，没在里面的就是没有流量，稀疏矩阵就是这个意思
        %之所以用这种表示形式，因为matlab库需要图以这种形式存储
        
        Traf; %所有流量
        T_DG1; %源节点id
        T_DG2; %目标节点id
        
        lvl_ncnt;
        total_ncnt;
        
        %cleared before every call of solve()
        collector;
        
        
    end
    
    methods(Static)
        
        %TEST
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function testng()
           
            afrp = FrpLab();
            
            agm = GraphMaker(afrp);
            
            assert(isequal(agm.lvl_ncnt,[1 4 16 1]),'err');
            
            assert(agm.nid2gidx([1 1]) == 1,'err');
            assert(agm.nid2gidx([2 3]) == 4,'err');
            assert(agm.nid2gidx([3 3]) == 8,'err');
            assert(agm.nid2gidx([4 1]) == 22,'err');
            
            assert(agm.gidx2lvl(1) == 1,'err');
            assert(agm.gidx2lvl(5) == 2,'err');
            assert(agm.gidx2lvl(21) == 3,'err');
            assert(agm.gidx2lvl(22) == 4,'err');
            
            fprintf(1,'ALL OK\n');
            
            
        end
        
        function test()
            
           afrp = FrpLab();
           
           afrp.I = 2;
           afrp.J = 4;
           afrp.TAR_traf = 10;
           
           afrp = afrp.setup();
            
           gm = GraphMaker(afrp);
           
           gm = gm.makeGraph();
           
           aG = gm.G;
           
           %检查图构建是否正确
           edge_count = afrp.I + afrp.I*afrp.J + afrp.J;
           assert(aG.cur_eidx == edge_count, 'err');
           
           aGsub = gm.getGsub();
           
           assert(aGsub.cur_eidx >= edge_count, 'err');
           
           
           
           
           fprintf(1,'ALL OK\n'); 
        end

%         function testWithFrp(afrp)
%            
%              %产生图对象
%             gm = GraphMaker(afrp);
%            
%             %构造原始图，对应算法步骤 1 2
%             
%             gm = gm.makeGraph();
%            
%             %test SGraph from makegraph
%             G = gm.G;
%             
%             assert(1,'');
%             assert(1,'');
%             assert(1,'');
%             assert(1,'');
%             assert(1,'');
%             assert(1,'');
%             
%             
%         end
        
        %求解过程即：
        %   针对当前图G得到补图Gsub
        %   在Gsub上得到最短路径(以权值计算)
        %   将得到的路径的值更新到图G中去
        
        
        function gm = solve(afrp)
            
            
            
            %产生图对象
            gm = GraphMaker(afrp);
           
            %构造原始图，对应算法步骤 1 2
            
            gm = gm.makeGraph();
                  
            %reinited
            gm.collector = GraphCollector(afrp);
            
            %迭代求解，对应算法步骤 3
                
                f = 0;
                k = afrp.TAR_traf;
                k_100 = 10;
                %%DEBUG
                %Gsub_list = {zeros(1,round(1+k/100)+1};
                %%%
                
                
                has_solution = 1;
                
                flow_inc = afrp.flow_inc;

                
                fprintf(1,'开始求解最小费用最大流...\n');
                
                %ct = 0;
                %tic;
                
                while(f < k)
                     
                    %ct = toc
                    %tic;
                    
                    %验证每层间的流量是否相等
                    gm.assert_getLvlTraf();
                    traf_vec = gm.getTrafVec();
                    f = traf_vec(1);    
                    
                    %打印进度信息
                    if( rem(f,k_100) == 0)

                        fprintf(1,'%.1f%% f=%d k=%d\n',round(f*100/k),f,k);
                        gm.collector  = gm.collector.collect(gm);
                    end
                    
                    %3.2
                    %Gsub里每条边的Cap flow都是不用的，我们只把存在的边和对应权值存进去
                    %每次流量是加到G上的
                    %fprintf(1,'获取补图\n');
                    Gsub = gm.getGsub();
                    
                    %DEBUG
                    %gm.printEdgeCont(Gsub,'w');
                    
                    %3.3: 求流量1的最短路径
                    %fprintf(1,'求解最短路径\n');
                    [dist,opath,path,pred] = Gsub.getshortestpath(1,sum(gm.lvl_ncnt));
                    
                    %DEBUG
                    %path
                    
                    if dist == Inf
                        has_solution  = 0;
                        break;
                    end
                    
                    %%%%%%%%%%%%分析
                    %%%首先我拿到最短路径
                    %1. 这个最短路径，i到i+1,可能是正向边，也可能是反向边。我可以判断，正向边，设v1->v2, 必有
                    %v1<v2,因为都是低层到高层的，
                    %
                    %
                    
                    %path
                    
                    %keys(gm.G.map_edge), values(gm.G.map_edge)
                    
                    %gm.G.Traf
                    
                    %
                    %将流量更新到原图G中
                    for i=1:length(path)-1
                        
                        %是个正向边
                        if( path(i) < path(i+1))
                            tmp_edge = SEdge(-1,path(i),-1,path(i+1),-1,0,flow_inc);
                            gm.G = gm.G.addTraf(tmp_edge);                            
                        elseif ( path(i) > path(i+1))
                            tmp_edge = SEdge(-1,path(i+1),-1,path(i),-1,0,-flow_inc);
                            gm.G = gm.G.addTraf(tmp_edge);
                        else
                            assert(1==0, 'err: path(i) == path(i+1)');
                        end


                        
                    end
                    %gm.G.Traf
                    %TODO:看流量内部存储空间是否正确
                    

                end
                
                if(has_solution == 0)
                    fprintf(1,'no solution\n');
                elseif(has_solution == 1)
                    
                    fprintf(1,'get solution\n');
                   
                    %traf_list = gm.dbg_getLvlTraf(); 
                    
                end
            
            
        end
        
    end
    
    
    methods
        
        function self=GraphMaker(frp)
            
            self.frp = frp;
            
            self = self.reinitGraph();
            
        end
        
        
        %nid是向量，第一个元素是层数，后面的是对应的下标
        %下标是从1开始
        %如2层节点下标1,1,1是第一个元素, 2,1,1是前面有T*I个元素了，[2 1 1]-1 = [1 0 0] ,
        %再*[self.T*I self.I 1]
        %
        function nidx = nid2gidx(self,nid)
            
            lvl = nid(1);
            
            %start_idx指这层节点开始之前的下标，即若第一个节点转为数字1， 就是start_idx+数字,
            %即加上该数字，若转为0,则 start_idx+1+数字
            %
            
           
            start_idx = 0; %第一层
            
            if lvl > 1
               start_idx = sum(self.lvl_ncnt(1:lvl-1)); 
            end
            
            if(lvl == 1)
                nidx = 1;
            elseif(lvl == 2)
                nidx = start_idx + nid(2);
            elseif(lvl == 3)
                nidx = start_idx + nid(2);
            elseif(lvl == 4)
                nidx = start_idx + 1;
            end
            
            
            
        end

        function lvl = gidx2lvl(self,gidx)
            
           
            cnt = 0;
            for i=1:4
               
                cnt = cnt + self.lvl_ncnt(i);
                if(gidx<=cnt)
                   lvl = i;
                   return;
                end
                
                
            end
            
             throw(MException('GraphMaker::gidx2lvl','no level found for gidx'));
            
            
        end
        
        
        
        function obj=reinitGraph(self)
        
            
            afrp = self.frp;
            
            %每层的节点数量，起点 区域节点  资源节点  终点
            self.lvl_ncnt=[ 1	afrp.J	afrp.I  1 ];
            
            %总节点数目
            self.total_ncnt = sum(self.lvl_ncnt);
            
            max_ecnt = 4*afrp.I*afrp.J;
            
            self.G = SGraph(max_ecnt); 
            
            %res_reqc向量，每元素是云节点c分到的请求量
            %self.res_reqc = sum(sum(afrp.res_zcit,3),2).*afrp.rc;
            
            obj=self;
            
        end
        
        
        %得到一个SEdge类对象
        
        function sedge=Eg(self,nid1,nid2,cap,wt,tr)
            
            sedge = SEdge(nid1,self.nid2gidx(nid1),nid2,self.nid2gidx(nid2),cap,wt,tr);
        end
        
        
        %产生最初始的原图G
        %!!!要求每条边都必须在
        function obj=makeGraph(self)
            
            self=self.reinitGraph();
            afrp = self.frp;
            I = afrp.I;
            J = afrp.J;
            
            %构建初始的图，边都有，流量为0，权值设为0
            
            
            %首先初始化所有fi,fij,fj的流量为0
            for j = 1:J
                %所有fj流量为0，容量无限(-1),权重0
                    self.G = self.G.pushEdge(self.Eg([1 1],[2 j],-1,0,0));
                %所有f_i^j流量为0，容量无限(-1),权重为Rloc(1-Pr(Dij>=1))
                %所有f_j^i流量为0，容量无限(-1),权重为无限，因为无流量。
                    for i=1:I
                        self.G = self.G.pushEdge(self.Eg([2 j],[3 i],-1,0,0));
                        
                    end
                %所有fj流量为0，容量无限(-1),权重0
                
            end
            
            %初始化i->y的边
            for i=1:I
                
                self.G = self.G.pushEdge(self.Eg([3 i],[4 1],-1,0,0));
                
            end
            
            
%             %首先初始化所有fi,fij,fj的流量为0
%             for j = 1:J
%                 %所有fj流量为0，容量无限(-1),权重0
%                     self.G = self.G.pushEdge(self.Eg([1],[2 j],-1,0,0));
%                 %所有f_i^j流量为0，容量无限(-1),权重为Rloc(1-Pr(Dij>=1))
%                 %所有f_j^i流量为0，容量无限(-1),权重为无限，因为无流量。
%                     for i=1:I
%                         wt = self.frp.wloc * (1-poisscdf(1,self.frp.Dia(i,j)));
%                         self.G = self.G.pushEdge(self.Eg([2 j],[3 i],-1,wt,0));
%                         self.G = self.G.pushEdge(self.Eg([3 i],[2 j],-1,100000,0));
%                         
%                     end
%                 %所有fj流量为0，容量无限(-1),权重0
%                 
%             end
%             
%             %初始化i->y的边
%             for i=1:I
%                 
%                 self.G = self.G.pushEdge(self.Eg([3 i],[4],-1,0,0));
%                 
%             end
            
            obj=self;
            
        end
        
        
        
        %根据当前图G的得到补图(residula graph)Gsub,根据rp论文lemma 6.6
        %
        
        
        function Gsub=getGsub(self)
           
            aG = self.G;
            %这是个空的图
            %残图不在于容量了，只在于有没有>=1,添加进去的边，默认都是联通的，容量为1
            %即DG1 DG2里有的节点和W是有用的，其他cap traf都是不用的
            Gsub = SGraph(aG.max_edges);
            
            %遍历所有边，更新或添加容量，权值
            afrp = self.frp;
            I = afrp.I;
            J = afrp.J;

            for j = 1:J
                %1-2层:
                %容量无限,权值一直是0,流量0
                    Gsub = Gsub.pushEdge(self.Eg([1 1],[2 j],-1,0,0)); 

                for i=1:I
                    %2-3层:
                    %容量无限,权值是Rloc(1-Pr(Dij>=traf+1)),容量无限,流量是0
                    %找到对应流量计算权值
                    tedge = self.Eg([2 j],[3 i],-1,0,0);
                    traf_v = self.G.getTrafValue(tedge);
                    wt  = afrp.wloc*poisscdf(traf_v+1,self.frp.Mij(i,j));
                    %添加边
                    tedge = tedge.setWeight(wt);
                    Gsub = Gsub.pushEdge(tedge);
                    
                    %3-2层
                    tedge = self.Eg([3 i],[2 j],-1,0,0);
                        %原图中没有反向边，这里使用的流的权值根据正向边的流量来决定。
                        %traf_v = self.G.getTrafValue(tedge);
                    %容量无限,权值是-Rloc(1-Pr(Dij>=traf)),容量无限,流量是0
                    %如果原图中2-3流量为0，则这里权值为无穷
                    if traf_v <= 0
                    	wt = 99999; 
                    else
                            
                        wt = -1*afrp.wloc*poisscdf(traf_v,self.frp.Mij(i,j));
                    end

                    tedge.setWeight(wt);
                    Gsub = Gsub.pushEdge(tedge);
                    
                end
            end
            

            for i=1:I
                %3-4层：
                %找到对应流量计算权值
                tedge = self.Eg([3 i],[4 1],-1,0,0);
                traf_v = self.G.getTrafValue(tedge);
                %容量无限,权值是Rsat(1-Pr(Dij>=traf)),容量无限,流量是0
                wt = afrp.wsat*poisscdf(traf_v,self.frp.Mi(i));
                tedge.setWeight(wt);
                Gsub = Gsub.pushEdge(tedge);
            end
            
          
        end
        
        function traf_v = getTrafValue(self, aedge)
           
            traf_v = self.G.getTrafValue(aedge);
            
        end

     function printEdgeCont(self,aG,aType)
         
            afrp = self.frp;
            
            I = afrp.I;
            J = afrp.J;
            
            
            
            for j=1:J
               display(sprintf('[1] -> [2,%d]: %d',j,aG.getPropValue(self.Eg([1 1],[2 j],-1,0,0),aType)));
               
               
            
            end

            for j=1:J
               for i=1:I
                  display(sprintf('[2,%d] -> [3,%d]: %d',j,i,aG.getPropValue(self.Eg([2 j],[3 i],-1,0,0),aType)));
                  
               end
            end

            
            for i=1:I
                display(sprintf('[3,%d] -> [4]: %d',i,aG.getPropValue(self.Eg([3 i],[4 1],-1,0,0),aType)));
                
            end
        
         
         
     end
        
     function printTraf(self,aG)
        self.printEdgeCont(aG,'traf');
    end
       
        
        function traf_vec = getTrafVec(self)
            
             afrp = self.frp;
            gm = self;
            I = afrp.I;
            J = afrp.J;
            
            traf_vec = zeros(1,3);
            
            for j=1:J
               traf_vec(1) = traf_vec(1) + gm.G.getTrafValue(gm.Eg([1 1],[2 j],-1,0,0)); 
               
               for i=1:I
                  traf_vec(2) = traf_vec(2) + gm.G.getTrafValue(gm.Eg([2 j],[3 i],-1,0,0)); 
               end
            
            end
            
            for i=1:I
               traf_vec(3) = traf_vec(3) +  gm.G.getTrafValue(gm.Eg([3 i],[4 1],-1,0,0)); 
            end
            
            
           
        end
 
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%lots of assert and test
        
        
        %结果完成时，测试各层之间的流量总和是否对得上
        function obj=assert_getLvlTraf(self)
            
            traf_vec = self.getTrafVec();
            
            %fprintf(1,'LVL_TRAF %d %d %d\n',traf_vec(1),traf_vec(2),traf_vec(3));
            assert(traf_vec(1) == traf_vec(2), 'error: 1-2 traffic != 2-3 traffic');
            assert(traf_vec(2) == traf_vec(3), 'error: 2-3 traffic != 3-4 traffic');
            
            %fprintf(1,'ASSERT: OK:LVL_TRAF\n');
            obj=self;
           
        end
        
        function obj=assert_sgraph(self)
            
            
            
            
           obj = self; 
        end

        
    end
    
end

