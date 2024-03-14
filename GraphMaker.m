classdef GraphMaker
    %GRAPHMAKE Summary of this class goes here
    %   Detailed explanation goes here
    
    %�ڵ���������ʾ����һ��Ԫ���ǲ�����������Ƕ�Ӧ���±�
    
    properties
        
        frp;
        
        %%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%
        %%%ԭͼG����ͼGsup;

        G;
        Gsup;
        
        %��ʾ���е�����������û������ľ���û��������ϡ�������������˼
        %֮���������ֱ�ʾ��ʽ����Ϊmatlab����Ҫͼ��������ʽ�洢
        
        Traf; %��������
        T_DG1; %Դ�ڵ�id
        T_DG2; %Ŀ��ڵ�id
        
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
           
           %���ͼ�����Ƿ���ȷ
           edge_count = afrp.I + afrp.I*afrp.J + afrp.J;
           assert(aG.cur_eidx == edge_count, 'err');
           
           aGsub = gm.getGsub();
           
           assert(aGsub.cur_eidx >= edge_count, 'err');
           
           
           
           
           fprintf(1,'ALL OK\n'); 
        end

%         function testWithFrp(afrp)
%            
%              %����ͼ����
%             gm = GraphMaker(afrp);
%            
%             %����ԭʼͼ����Ӧ�㷨���� 1 2
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
        
        %�����̼���
        %   ��Ե�ǰͼG�õ���ͼGsub
        %   ��Gsub�ϵõ����·��(��Ȩֵ����)
        %   ���õ���·����ֵ���µ�ͼG��ȥ
        
        
        function gm = solve(afrp)
            
            
            
            %����ͼ����
            gm = GraphMaker(afrp);
           
            %����ԭʼͼ����Ӧ�㷨���� 1 2
            
            gm = gm.makeGraph();
                  
            %reinited
            gm.collector = GraphCollector(afrp);
            
            %������⣬��Ӧ�㷨���� 3
                
                f = 0;
                k = afrp.TAR_traf;
                k_100 = 10;
                %%DEBUG
                %Gsub_list = {zeros(1,round(1+k/100)+1};
                %%%
                
                
                has_solution = 1;
                
                flow_inc = afrp.flow_inc;

                
                fprintf(1,'��ʼ�����С���������...\n');
                
                %ct = 0;
                %tic;
                
                while(f < k)
                     
                    %ct = toc
                    %tic;
                    
                    %��֤ÿ���������Ƿ����
                    gm.assert_getLvlTraf();
                    traf_vec = gm.getTrafVec();
                    f = traf_vec(1);    
                    
                    %��ӡ������Ϣ
                    if( rem(f,k_100) == 0)

                        fprintf(1,'%.1f%% f=%d k=%d\n',round(f*100/k),f,k);
                        gm.collector  = gm.collector.collect(gm);
                    end
                    
                    %3.2
                    %Gsub��ÿ���ߵ�Cap flow���ǲ��õģ�����ֻ�Ѵ��ڵıߺͶ�ӦȨֵ���ȥ
                    %ÿ�������Ǽӵ�G�ϵ�
                    %fprintf(1,'��ȡ��ͼ\n');
                    Gsub = gm.getGsub();
                    
                    %DEBUG
                    %gm.printEdgeCont(Gsub,'w');
                    
                    %3.3: ������1�����·��
                    %fprintf(1,'������·��\n');
                    [dist,opath,path,pred] = Gsub.getshortestpath(1,sum(gm.lvl_ncnt));
                    
                    %DEBUG
                    %path
                    
                    if dist == Inf
                        has_solution  = 0;
                        break;
                    end
                    
                    %%%%%%%%%%%%����
                    %%%�������õ����·��
                    %1. ������·����i��i+1,����������ߣ�Ҳ�����Ƿ���ߡ��ҿ����жϣ�����ߣ���v1->v2, ����
                    %v1<v2,��Ϊ���ǵͲ㵽�߲�ģ�
                    %
                    %
                    
                    %path
                    
                    %keys(gm.G.map_edge), values(gm.G.map_edge)
                    
                    %gm.G.Traf
                    
                    %
                    %���������µ�ԭͼG��
                    for i=1:length(path)-1
                        
                        %�Ǹ������
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
                    %TODO:�������ڲ��洢�ռ��Ƿ���ȷ
                    

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
        
        
        %nid����������һ��Ԫ���ǲ�����������Ƕ�Ӧ���±�
        %�±��Ǵ�1��ʼ
        %��2��ڵ��±�1,1,1�ǵ�һ��Ԫ��, 2,1,1��ǰ����T*I��Ԫ���ˣ�[2 1 1]-1 = [1 0 0] ,
        %��*[self.T*I self.I 1]
        %
        function nidx = nid2gidx(self,nid)
            
            lvl = nid(1);
            
            %start_idxָ���ڵ㿪ʼ֮ǰ���±꣬������һ���ڵ�תΪ����1�� ����start_idx+����,
            %�����ϸ����֣���תΪ0,�� start_idx+1+����
            %
            
           
            start_idx = 0; %��һ��
            
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
            
            %ÿ��Ľڵ���������� ����ڵ�  ��Դ�ڵ�  �յ�
            self.lvl_ncnt=[ 1	afrp.J	afrp.I  1 ];
            
            %�ܽڵ���Ŀ
            self.total_ncnt = sum(self.lvl_ncnt);
            
            max_ecnt = 4*afrp.I*afrp.J;
            
            self.G = SGraph(max_ecnt); 
            
            %res_reqc������ÿԪ�����ƽڵ�c�ֵ���������
            %self.res_reqc = sum(sum(afrp.res_zcit,3),2).*afrp.rc;
            
            obj=self;
            
        end
        
        
        %�õ�һ��SEdge�����
        
        function sedge=Eg(self,nid1,nid2,cap,wt,tr)
            
            sedge = SEdge(nid1,self.nid2gidx(nid1),nid2,self.nid2gidx(nid2),cap,wt,tr);
        end
        
        
        %�������ʼ��ԭͼG
        %!!!Ҫ��ÿ���߶�������
        function obj=makeGraph(self)
            
            self=self.reinitGraph();
            afrp = self.frp;
            I = afrp.I;
            J = afrp.J;
            
            %������ʼ��ͼ���߶��У�����Ϊ0��Ȩֵ��Ϊ0
            
            
            %���ȳ�ʼ������fi,fij,fj������Ϊ0
            for j = 1:J
                %����fj����Ϊ0����������(-1),Ȩ��0
                    self.G = self.G.pushEdge(self.Eg([1 1],[2 j],-1,0,0));
                %����f_i^j����Ϊ0����������(-1),Ȩ��ΪRloc(1-Pr(Dij>=1))
                %����f_j^i����Ϊ0����������(-1),Ȩ��Ϊ���ޣ���Ϊ��������
                    for i=1:I
                        self.G = self.G.pushEdge(self.Eg([2 j],[3 i],-1,0,0));
                        
                    end
                %����fj����Ϊ0����������(-1),Ȩ��0
                
            end
            
            %��ʼ��i->y�ı�
            for i=1:I
                
                self.G = self.G.pushEdge(self.Eg([3 i],[4 1],-1,0,0));
                
            end
            
            
%             %���ȳ�ʼ������fi,fij,fj������Ϊ0
%             for j = 1:J
%                 %����fj����Ϊ0����������(-1),Ȩ��0
%                     self.G = self.G.pushEdge(self.Eg([1],[2 j],-1,0,0));
%                 %����f_i^j����Ϊ0����������(-1),Ȩ��ΪRloc(1-Pr(Dij>=1))
%                 %����f_j^i����Ϊ0����������(-1),Ȩ��Ϊ���ޣ���Ϊ��������
%                     for i=1:I
%                         wt = self.frp.wloc * (1-poisscdf(1,self.frp.Dia(i,j)));
%                         self.G = self.G.pushEdge(self.Eg([2 j],[3 i],-1,wt,0));
%                         self.G = self.G.pushEdge(self.Eg([3 i],[2 j],-1,100000,0));
%                         
%                     end
%                 %����fj����Ϊ0����������(-1),Ȩ��0
%                 
%             end
%             
%             %��ʼ��i->y�ı�
%             for i=1:I
%                 
%                 self.G = self.G.pushEdge(self.Eg([3 i],[4],-1,0,0));
%                 
%             end
            
            obj=self;
            
        end
        
        
        
        %���ݵ�ǰͼG�ĵõ���ͼ(residula graph)Gsub,����rp����lemma 6.6
        %
        
        
        function Gsub=getGsub(self)
           
            aG = self.G;
            %���Ǹ��յ�ͼ
            %��ͼ�����������ˣ�ֻ������û��>=1,��ӽ�ȥ�ıߣ�Ĭ�϶�����ͨ�ģ�����Ϊ1
            %��DG1 DG2���еĽڵ��W�����õģ�����cap traf���ǲ��õ�
            Gsub = SGraph(aG.max_edges);
            
            %�������бߣ����»����������Ȩֵ
            afrp = self.frp;
            I = afrp.I;
            J = afrp.J;

            for j = 1:J
                %1-2��:
                %��������,Ȩֵһֱ��0,����0
                    Gsub = Gsub.pushEdge(self.Eg([1 1],[2 j],-1,0,0)); 

                for i=1:I
                    %2-3��:
                    %��������,Ȩֵ��Rloc(1-Pr(Dij>=traf+1)),��������,������0
                    %�ҵ���Ӧ��������Ȩֵ
                    tedge = self.Eg([2 j],[3 i],-1,0,0);
                    traf_v = self.G.getTrafValue(tedge);
                    wt  = afrp.wloc*poisscdf(traf_v+1,self.frp.Mij(i,j));
                    %��ӱ�
                    tedge = tedge.setWeight(wt);
                    Gsub = Gsub.pushEdge(tedge);
                    
                    %3-2��
                    tedge = self.Eg([3 i],[2 j],-1,0,0);
                        %ԭͼ��û�з���ߣ�����ʹ�õ�����Ȩֵ��������ߵ�������������
                        %traf_v = self.G.getTrafValue(tedge);
                    %��������,Ȩֵ��-Rloc(1-Pr(Dij>=traf)),��������,������0
                    %���ԭͼ��2-3����Ϊ0��������ȨֵΪ����
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
                %3-4�㣺
                %�ҵ���Ӧ��������Ȩֵ
                tedge = self.Eg([3 i],[4 1],-1,0,0);
                traf_v = self.G.getTrafValue(tedge);
                %��������,Ȩֵ��Rsat(1-Pr(Dij>=traf)),��������,������0
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
        
        
        %������ʱ�����Ը���֮��������ܺ��Ƿ�Ե���
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

