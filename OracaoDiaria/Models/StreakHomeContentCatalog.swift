//
//  StreakHomeContentCatalog.swift
//  OracaoDiaria
//
//  Created by Codex on 20/03/26.
//

import Foundation

struct StreakHomeVerse: Identifiable {
    let text: String
    let reference: String

    var id: String { reference }
}

enum StreakHomeContentCatalog {
    static let completedMessages: [String] = [
        "🙏 Você já falou com Deus hoje. O dia começou no eixo.",
        "✨ Seu coração já encontrou direção nesta manhã.",
        "🌤️ Você já separou um tempo com Deus hoje.",
        "🔥 Sua chama já foi acesa antes da correria.",
        "🤍 Você já entregou o dia nas mãos certas.",
        "🕊️ Sua voz já encontrou o céu hoje.",
        "🌿 Sua alma já respirou presença nesta manhã.",
        "☀️ Você já começou o dia por dentro.",
        "📖 Seu espírito já recebeu alimento hoje.",
        "🙌 Você já respondeu ao convite da presença.",
        "💙 Seu coração já foi reorganizado com oração.",
        "🌸 Você já abriu espaço para Deus no começo do dia.",
        "🙏 Hoje você já escolheu presença antes da pressa.",
        "✨ Sua rotina já foi atravessada pela graça.",
        "🔥 Você já colocou Deus no centro do hoje.",
        "🕊️ Hoje sua oração já subiu.",
        "🌿 Sua fé já foi regada logo cedo.",
        "☁️ O dia já ficou mais leve porque você orou.",
        "🤲 Você já entregou seus pesos ao Pai hoje.",
        "🌞 Seu começo já recebeu luz do céu.",
        "💫 Você já construiu um momento santo hoje.",
        "📖 Hoje você já começou pela parte eterna.",
        "🤍 Sua manhã já foi visitada pela presença.",
        "🙌 Você já fez do comum um altar hoje.",
        "🌊 Seu coração já encontrou descanso em Deus.",
        "💛 Hoje você já fortaleceu o invisível.",
        "🌤️ Sua manhã já teve comunhão.",
        "🌼 Você já semeou paz no seu dia.",
        "🫶 Hoje você já se aproximou do Pai.",
        "🔥 Sua constância está sendo construída hoje.",
        "🕯️ Você já parou para ouvir Deus nesta manhã.",
        "🌈 Seu dia já começou em boa direção."
    ]

    static let pendingMessages: [String] = [
        "🙏 Ainda dá tempo de falar com Deus hoje.",
        "✨ Seu momento com Deus ainda está te esperando.",
        "🌤️ O céu continua aberto para você hoje.",
        "🔥 Sua chama ainda pode ser reacendida agora.",
        "🤍 Ainda dá para entregar o dia nas mãos de Deus.",
        "🕊️ Deus continua perto, mesmo no meio da correria.",
        "🌿 Sua alma ainda merece esse respiro hoje.",
        "☀️ Ainda existe tempo para começar por dentro.",
        "📖 Seu espírito ainda pode receber alimento hoje.",
        "🙌 Ainda dá para responder ao convite da presença.",
        "💙 Seu coração ainda pode encontrar direção hoje.",
        "🌸 Ainda dá para honrar o hoje com oração.",
        "🙏 Seu tempo com Deus ainda cabe neste dia.",
        "✨ A graça ainda pode atravessar sua rotina agora.",
        "🔥 Ainda dá para colocar Deus no centro do dia.",
        "🕊️ Sua oração ainda pode subir hoje.",
        "🌿 Sua fé ainda pode ser regada hoje.",
        "☁️ O dia ainda pode ficar mais leve com oração.",
        "🤲 Você ainda pode entregar seus pesos ao Pai.",
        "🌞 Ainda dá para clarear o dia por dentro.",
        "💫 Ainda dá para construir um momento santo hoje.",
        "📖 Ainda dá para começar pela parte eterna.",
        "🤍 Sua alma ainda pode ser visitada pela presença.",
        "🙌 Ainda dá para fazer do comum um altar.",
        "🌊 Seu coração ainda pode encontrar descanso em Deus.",
        "💛 Ainda há espaço para graça no seu hoje.",
        "🌤️ Seu encontro com Deus ainda pode acontecer hoje.",
        "🌼 Ainda dá para plantar paz no restante do dia.",
        "🫶 Seu momento com o Pai ainda está disponível.",
        "🔥 Sua chama não apagou; só precisa de presença.",
        "🕯️ Ainda dá para silenciar o barulho e ouvir Deus.",
        "🌈 O seu hoje ainda pode ganhar direção."
    ]

    static let verses: [StreakHomeVerse] = [
        .init(text: "“Guarde o coração, porque dele brotam as fontes da vida.”", reference: "Provérbios 4:23"),
        .init(text: "“Seja pronto para ouvir, tardio para falar e tardio para se irar.”", reference: "Tiago 1:19"),
        .init(text: "“Em vez de ansiedade, apresente tudo a Deus em oração, e a paz guardará seu coração.”", reference: "Filipenses 4:6-7"),
        .init(text: "“A resposta branda desvia o furor, mas a palavra dura provoca a ira.”", reference: "Provérbios 15:1"),
        .init(text: "“O Senhor pede justiça, misericórdia e humildade no caminhar com Ele.”", reference: "Miqueias 6:8"),
        .init(text: "“Faça de todo o coração, como quem serve ao Senhor.”", reference: "Colossenses 3:23"),
        .init(text: "“Não se canse de fazer o bem; no tempo certo haverá fruto.”", reference: "Gálatas 6:9"),
        .init(text: "“Que da sua boca saia apenas o que edifica e comunica graça.”", reference: "Efésios 4:29"),
        .init(text: "“Consagre ao Senhor tudo o que fizer, e seus planos encontrarão firmeza.”", reference: "Provérbios 16:3"),
        .init(text: "“Onde estiver o seu tesouro, aí também estará o seu coração.”", reference: "Mateus 6:21"),
        .init(text: "“Não viva no piloto automático deste mundo; deixe Deus renovar sua mente.”", reference: "Romanos 12:2"),
        .init(text: "“Se falta sabedoria, peça a Deus, que dá com generosidade.”", reference: "Tiago 1:5"),
        .init(text: "“O fruto do Espírito é amor, alegria, paz, paciência, bondade, fidelidade, mansidão e domínio próprio.”", reference: "Gálatas 5:22-23"),
        .init(text: "“A língua tem poder de vida e de morte.”", reference: "Provérbios 18:21"),
        .init(text: "“Há tempo certo para cada propósito debaixo do céu.”", reference: "Eclesiastes 3:1"),
        .init(text: "“Venha a Cristo e encontre descanso para a alma cansada.”", reference: "Mateus 11:28-30"),
        .init(text: "“A palavra de Deus é lâmpada para os pés e luz para o caminho.”", reference: "Salmo 119:105"),
        .init(text: "“Quem reparte com generosidade também será renovado.”", reference: "Provérbios 11:25"),
        .init(text: "“O amor vivido é a marca mais visível de quem segue Jesus.”", reference: "João 13:34-35"),
        .init(text: "“A disciplina amadurece e depois produz fruto de justiça.”", reference: "Hebreus 12:11"),
        .init(text: "“Deus não deu espírito de medo, mas de poder, amor e equilíbrio.”", reference: "2 Timóteo 1:7"),
        .init(text: "“Que sua palavra seja simples e verdadeira.”", reference: "Mateus 5:37"),
        .init(text: "“Assim como o ferro afia o ferro, pessoas também se fortalecem mutuamente.”", reference: "Provérbios 27:17"),
        .init(text: "“Alegre-se, ore sem cessar e agradeça em toda circunstância.”", reference: "1 Tessalonicenses 5:16-18"),
        .init(text: "“Não seja vencido pelo mal; vença o mal com o bem.”", reference: "Romanos 12:21"),
        .init(text: "“Fale com graça e sabedoria.”", reference: "Colossenses 4:6"),
        .init(text: "“O coração alegre favorece a cura.”", reference: "Provérbios 17:22"),
        .init(text: "“Quem é fiel no pouco também é fiel no muito.”", reference: "Lucas 16:10"),
        .init(text: "“Viva com sabedoria e aproveite bem o tempo.”", reference: "Efésios 5:15-16"),
        .init(text: "“Lance sobre Deus toda ansiedade, porque Ele cuida de você.”", reference: "1 Pedro 5:7"),
        .init(text: "“Há palavras que ferem como espada, mas a língua sábia cura.”", reference: "Provérbios 12:18"),
        .init(text: "“Considere os outros com humildade e cuidado sincero.”", reference: "Filipenses 2:3-4"),
        .init(text: "“Nem toda pressa produz fruto; Deus também dá descanso.”", reference: "Salmo 127:2"),
        .init(text: "“A verdade liberta.”", reference: "João 8:32"),
        .init(text: "“As misericórdias do Senhor se renovam a cada manhã.”", reference: "Lamentações 3:22-23"),
        .init(text: "“Busque primeiro o Reino de Deus, e o resto encontrará lugar.”", reference: "Mateus 6:33")
    ]
}
