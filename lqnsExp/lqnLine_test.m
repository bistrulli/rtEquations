clear

f = waitbar(0,'Simulation Init');

nexp=1;
e=[];
P=zeros(nexp,3);
nclients=zeros(nexp,1);
runtime=zeros(nexp,1);

for i=1:nexp
    
    waitbar(i/nexp,f,'Simulationg...');
    
    nclients(i)=randi([100,300]);
    P(i,:)=randi([1,10],1,3);
    
%     model = LayeredNetwork('myLayeredModel');
%     
%     P1 = Processor(model, 'P1', nclients(i), SchedStrategy.INF);
%     P2 = Processor(model, 'P2', P(i,1), SchedStrategy.FCFS);
%     P3 = Processor(model, 'P3', P(i,2), SchedStrategy.FCFS);
%     P4 = Processor(model, 'P4', P(i,3), SchedStrategy.FCFS);
%     
%     T1 = Task(model, 'T1', nclients(i), SchedStrategy.REF).on(P1);
%     T2 = Task(model, 'T2', nclients(i), SchedStrategy.FCFS).on(P2);
%     T3 = Task(model, 'T3', nclients(i), SchedStrategy.FCFS).on(P3);
%     T4 = Task(model, 'T4', nclients(i), SchedStrategy.FCFS).on(P4);
%     
%     E1 = Entry(model, 'E1').on(T1);
%     E2 = Entry(model, 'E2').on(T2);
%     E3 = Entry(model, 'E3').on(T3);
%     E4 = Entry(model, 'E4').on(T4);
%     
%     A1 = Activity(model, 'A1', Exp(1.0)).on(T1).boundTo(E1).synchCall(E2,1.0);
%     A2 = Activity(model, 'A2', Exp(1.0)).on(T2).boundTo(E2).repliesTo(E2).synchCall(E3,1.0);
%     A3 = Activity(model, 'A3', Exp(1.0)).on(T3).boundTo(E3).repliesTo(E3).synchCall(E4,1.0);
%     A4 = Activity(model, 'A4', Exp(1.0)).on(T4).boundTo(E4).repliesTo(E4);
%     
%     options = SolverLN.defaultOptions;
%     options.iter_max=1000000;
%     %options.method='exact';
%     AvgTable = SolverLQNS(model,options).getAvgTable;
%     
    %qui devo fare un wrapper per lqn diff
    lqnsTmpl = fileread('simple-qn.lqn');
    variable=["$P1";"$P2";"$P3";"$P4";"$T1";"$T2";"$T3";"$T4"];
    replaces=[sprintf("%d",nclients(i));
        sprintf("%d",P(i,1));
        sprintf("%d",P(i,2));
        sprintf("%d",P(i,3));
        sprintf("%d",nclients(i));
        sprintf("%d",nclients(i));
        sprintf("%d",nclients(i));
        sprintf("%d",nclients(i))];
    newModel = replace(lqnsTmpl,variable,replaces);
    
    file=fopen('lqnDiffModel.lqn','w+');
    fprintf(file,'%s',newModel);
    tic();
    system(join(["java","-jar","/Users/emilio/Desktop/DiffLQN_0.1/DiffLQN.jar","lqnDiffModel.lqn"]));
    runtime(i)=toc();
    lqnDiffRes=readtable("lqnDiffModel.csv");
%     
%     e=[e,abs(AvgTable.RespT([end-3,end-2,end-1,end])-lqnDiffRes.Var4([end-3,end-2,end-1,end]))*100./lqnDiffRes.Var4([end-3,end-2,end-1,end])];
%     fig=boxplot(e);
    
    jmtTml=fileread("jmtTpl.jsimg");
    variable=["$user";"$P1";"$P2";"$P3";];
    replaces=[sprintf("%d",nclients(i));
        sprintf("%d",P(i,1));
        sprintf("%d",P(i,2));
        sprintf("%d",P(i,3));];
    newJmtModel = replace(jmtTml,variable,replaces);
    file=fopen('JMTModel.jsimg','w+');
    fprintf(file,'%s',newJmtModel);
    
    jmtModel=JMT2LINE("JMTModel.jsimg");
    opt = SolverJMT.defaultOptions;
    opt.method="jmva";
    solver = SolverJMT(jmtModel,opt);
    
    P2=[0,1,0,0;
        0,0,1,0;
        0,0,0,1;
        0,0,0,0;];
    MRT=solveRT2(P2,solver.getAvgRespT());
    
end

close(f);


