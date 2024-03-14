classdef SGraph
    %SGRAPH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        max_edges;
         
        
        %����Ĵ洢��ʽ����������ÿ��������Ӧһ���ߣ��ñߵ�idΪeidx����ÿ��������Ӧ����ͬ����
        
        %��ʾ���еıߣ�û������ľ���û�бߣ������Ϊ����Ϊ0
        %ע�⣺�����п���Ϊ0����������Ҫע�⴦��
        
        W; %�ߵ�Ȩֵ����
        %CAP -2 ˵����Ȼ��¼�˱ߣ����ñ���ɾ��
        Cap; %�ߵ���������
        
        Traf; %������С
        
        %������ DG1(eidx) �� DG2(eidx)����һ�������
        DG1; %Դ�ڵ�ID
        DG2; %Ŀ��ڵ�ID
        
        cur_eidx; %��ǰ��λ�ã�������������飬<=�������ֵ��ֵ�ǺϷ���
        
        %��edge (ID1 -> ID2) ӳ��Ϊ eidx
        
        map_edge;
       
    end
    
    methods(Static)
       

        
        function test()

            g = SGraph(100);           
                
            for i=1:6
                a = SEdge(i,i,i+1,i+1,1,1,i*3);
                
                g = g.pushEdge(a);

                a = SEdge(i,i,i+2,i+2,1,1,i*5);
                g = g.pushEdge(a);
                
            end
            
            for i=1:6
                g = g.addTraf(SEdge(i,i,i+1,i+1,1,1,7));
                assert(g.getTrafValue(SEdge(i,i,i+1,i+1,1,1,0)) == i*3+7,'err');
                assert(g.getTrafValue(SEdge(i,i,i+2,i+2,1,1,0)) == i*5,'err');
                
            end
            
            %g.DG1
            
            %[dist,opath,path,pred,dmap]  = g.getshortestpath(1,7)
            
            fprintf(1,'ALL OK\n');
            
        end
        
    end
    
    methods
        
        function self=SGraph(max_edges)
            
            self = self.resetGraph(max_edges);
        end
        
        function obj=resetGraph(self,max_edges)
            
            
            self.max_edges = max_edges;
            self.W = zeros(1,max_edges);
            self.Cap = zeros(1,max_edges);
            self.DG1 = zeros(1,max_edges);
            self.DG2 = zeros(1,max_edges);
            self.Traf = zeros(1,max_edges);
            
            self.cur_eidx=0;
            
            self.map_edge = containers.Map({0},{0});
           
            
            
            obj=self;
        end
        
        %aedge is [nid_fr, nid_to, capacity, weight]
        %pushʱͬʱ���������Ϣ��Traf T_DGx����ͬ�±괦
        %ע�⣺������һ���ߣ������Ѵ��ڣ��򱨴�
        function obj = pushEdge(self,aedge)
        
            
            %���Ȳ�ѯedge_map�����б����׳��쳣
            emidx = aedge.nidx1*100000+aedge.nidx2;
            
            %�������ǰ�ӹ���
            if(isKey(self.map_edge,emidx))
                
                throw(MException('SGraph:error','edge duplicated')); 
                
            end
            
            
            
            eidx = self.cur_eidx + 1;
            
           
            
            self.map_edge(emidx) = eidx;
            
            %fprintf(1,'cur_eidx: %d eidx: %d  wt: %d\n',self.cur_eidx,eidx,aedge.wt);
            
            self.DG1(eidx) = aedge.nidx1;
            self.DG2(eidx) = aedge.nidx2;
            self.Cap(eidx) = aedge.cap;
            self.W(eidx) = aedge.wt;
            self.Traf(eidx) = aedge.tr;
            
            
            self.cur_eidx = eidx;
            
            
            
            obj=self;
            
        end
        
        
        %update if exist, or push
%         function obj = updPushEdge(self,aedge)
%             
%             eidx = intersect(find(self.DG1==aedge.nidx1),find(self.DG2==aedge.nidx2));
%             
%             if(isempty(eidx))
%             	%�ҵ��ˣ����°� 
%                 self.Cap(eidx) = aedge.cap;
%                 self.W(eidx) = aedge.wt;
%                 self.Traf(eidx) = aedge.tr;
%             else
%                 %û�ҵ������
%                 self = self.pushEdge(aedge);
%             end
%             
%             
%             
%         	obj=self;
%             
%             
%         end
        
        function traf_idx = getTrafIndex(self,aflow)

            %�ҵ���Ӧ�±�
            emidx = aflow.nidx1*100000+aflow.nidx2;            

            
            
            traf_idx = self.map_edge(emidx);


        end

        function traf_v = getTrafValue(self,aflow)
            
            traf_v = self.getPropValue(aflow,'traf');

        end

        function prop_v = getPropValue(self,aflow,aType)
           
            traf_idx = self.getTrafIndex(aflow);
            
            
            
            if( strcmp(aType,'w'))
               prop_v = self.W(traf_idx); 
            elseif( strcmp(aType,'cap'))
               prop_v = self.Cap(traf_idx);
               
            elseif( strcmp(aType,'traf'))
                
               prop_v = self.Traf(traf_idx); 
            else
                throw(MException('SGraph:error_atype',aType));
            
            end
        end
        
        %ֻ�Ǹ������������������еıߣ�����������£��������
        %ע�⣺�Ǽ�������
        function obj = addTraf(self,aflow)
            
            traf_idx = self.getTrafIndex(aflow);
            
            self.Traf(traf_idx) = self.Traf(traf_idx)+aflow.tr;
            
            obj=self;
            
            
        end
        
        
        
        function [dist,opath,path,pred,dmap] = getshortestpath(self,gidx_fr,gidx_to)
            
            cnt = self.cur_eidx;
            if(cnt+2 > self.max_edges)
                msg = sprintf('idx (cnt+2)=(%d) > max_edges(%d)',cnt+2,self.max_edges);
                throw(MException('SGraph:error',msg));
            end
            dg1 = self.DG1(1:cnt+2);
            dg2 = self.DG2(1:cnt+2);
            w = self.W(1:cnt+2);
            
            
            %graphshortestpath����Ҫ��sparse��������б������
            %��sparse�����±�������ɶ��ľ��󣬾���̫��������Ҫת��
            %   ��:
            %       1.��ÿ��DG_1��_2�е�id,ת��Ϊһ��˳��id,��¼�����ϵ�ͷ����ϵ������ת��·��
            %           ��Ϊshortestpath������Ҫ�ڵ�ID��1��N֮�䶼�еģ����������ŵ�ID
            
            
                cur_id = 0;
                
                %������ת����id, ֵΪԭʼid
                dmap = ones(0,2*cnt);
                
                omap = containers.Map({0},{0});
                
                for i=1:cnt
                    
                    %x1�ǵ�ǰ�ߵ���ʼ�ڵ�ԭʼֵ
                    x1 = dg1(i);
                    
                    %x2�ǵ�ǰ�䶯��ֹ�ڵ�ԭʼֵ
                    x2 = dg2(i);
                    
                    
                    if(isempty(find(dmap==x1, 1)))
                       % no x1, add it
                       cur_id = cur_id + 1;
                       dmap(cur_id) = x1;
                       omap(x1)=cur_id;
                    end
                    
                    if(isempty(find(dmap==x2, 1)))
                       % no x1, add it
                       cur_id = cur_id + 1;
                       dmap(cur_id) = x2;
                       omap(x2) = cur_id;
                    end
                    
                    
                    
                    
                end
            
                %����dmap���Ƕ�Ӧ��ϵ�ˣ����ǰ�˳���滻
                for i=1:cnt
                   
                    dg1(i) = omap(dg1(i));
                    dg2(i) = omap(dg2(i));
                end
                
            
            
            
            %       2.����sparse·��ʱ��ע��DG_1��DG_2�е����ֵӦ���൱������������ͬ���еľ���
            %       �����һ���������һ���ߣ�ȨֵΪintmax
            
            max1 = max(dg1);
            max2 = max(dg2);
            
            rmax = max(max1,max2);
            
            dg1(cnt+1) = rmax;
            dg2(cnt+1) = rmax+1;
            w(cnt+1) = 0;
            
            dg1(cnt+2) = rmax+1;
            dg2(cnt+2) = rmax;
            w(cnt+2) = 0;
            
            %��w����һ������ֵ
            tDG = sparse(dg1,dg2,w+1);
            
           
            
            %ת��Դ��Ŀ���
            gidx_fr = find(dmap==gidx_fr,1);
            gidx_to = find(dmap==gidx_to,1);
            
            [dist,opath,pred] = graphshortestpath(tDG,gidx_fr,gidx_to);  
            
            
            %��������map,��ת��path
            path = opath;
            
            for i=1:length(path)
                
                path(i) = dmap(path(i));
                
            end
            
            
            
            
        end
        
    end
    
end

