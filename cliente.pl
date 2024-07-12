:- dynamic cliente/3.

% cliente(Codigo, Nome, CPF).
cliente(1, 'Eduardo', '111.222.333-44').
cliente(2, 'Pessoa 2', '555.666.777-88').
cliente(3, 'Pessoa 3', '999.888.777-66').

% Cadastro de cliente
cadastro_cliente :-
    writeln('--- Cadastro de Cliente ---'),
    writeln('Entrando no predicado cadastro_cliente'),
    writeln('Nome:'),
    read_line_to_string(user_input, Nome),
    format('Nome lido: ~w~n', [Nome]),
    writeln('CPF:'),
    read_line_to_string(user_input, CPF),
    format('CPF lido: ~w~n', [CPF]),
    findall(Codigo, cliente(Codigo, _, _), Codigos),
    length(Codigos, N),
    Codigo is N + 1,
    assertz(cliente(Codigo, Nome, CPF)),
    salvar_clientes,  % Salvar clientes após o cadastro
    writeln('Cliente cadastrado com sucesso!').

% Listar clientes
listar_clientes :-
    writeln('--- Lista de Clientes ---'),
    forall(cliente(Codigo, Nome, CPF),
        format('Codigo: ~w, Nome: ~w, CPF: ~w~n', [Codigo, Nome, CPF])).

% Excluir cliente
excluir_cliente :-
    writeln('--- Excluir Cliente ---'),
    writeln('Entrando no predicado excluir_cliente'),
    writeln('Codigo do Cliente:'),
    read_line_to_string(user_input, CodigoString),
    (   number_string(Codigo, CodigoString),
        cliente(Codigo, Nome, CPF) ->
        retract(cliente(Codigo, Nome, CPF)),
        salvar_clientes,  % Salvar clientes após a exclusão
        format('Cliente ~w (CPF: ~w) excluído com sucesso!~n', [Nome, CPF])
    ;   writeln('Cliente não encontrado ou código inválido.')
    ).

% Salvar clientes em um arquivo
salvar_clientes :-
    open('clientes.txt', write, Stream),
    forall(cliente(Codigo, Nome, CPF),
        format(Stream, 'cliente(~w, \'~w\', \'~w\').~n', [Codigo, Nome, CPF])),
    close(Stream).

% Carregar clientes de um arquivo
carregar_clientes :-
    (   exists_file('clientes.txt') ->
        open('clientes.txt', read, Stream),
        repeat,
        read(Stream, Term),
        (   Term == end_of_file ->
            close(Stream), !
        ;   assertz(Term),
            fail
        )
    ;   writeln('Arquivo clientes.txt não encontrado, inicializando sem dados persistidos.')
    ).

% Printar se foi carregado corretamente
:- writeln('cliente.pl carregado com sucesso').
:- carregar_clientes.