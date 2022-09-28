function [outputArg1,outputArg2] = callDiffLQN(model)
    %aggiorno il modello con il valore
    %eseguo il modello e prendo il risultato
    system(join(['lqns ',ignoreWarn,' --iteration-limit=',num2str(options.iter_max),' -Pstop-on-message-loss=false -x ',sprintf("'%s'",filename)],""));
end

