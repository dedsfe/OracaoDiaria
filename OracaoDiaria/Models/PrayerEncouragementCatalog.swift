//
//  PrayerEncouragementCatalog.swift
//  OracaoDiaria
//
//  Created by Codex on 17/03/26.
//

import Foundation

enum PrayerEncouragementGroup: String, CaseIterable, Hashable {
    case humorous
    case biblical
    case gentle
    case direct
    case poetic
    case wakeUp
    case discipline

    var displayName: String {
        switch self {
        case .humorous:
            return "Engraçadas"
        case .biblical:
            return "Bíblia"
        case .gentle:
            return "Carinhosas"
        case .direct:
            return "Diretas"
        case .poetic:
            return "Poéticas"
        case .wakeUp:
            return "Despertar"
        case .discipline:
            return "Disciplina"
        }
    }
}

enum PrayerEncouragementCatalog {
    static let grouped: [PrayerEncouragementGroup: [String]] = [
        .humorous: [
            "Seu feed aguenta. Sua oração vem primeiro.",
            "O app sobrevive sem você por alguns minutos. Ore.",
            "Nem a notificação está tão urgente quanto sua oração.",
            "Antes de abrir o mundo, abre o coração.",
            "O algoritmo pode esperar; Deus não precisa disputar atenção.",
            "Seu celular acordou. Sua alma também precisa.",
            "Rolou a tela? Agora rola uma oração.",
            "Menos scroll, mais salmo.",
            "Seu polegar já trabalhou. Agora deixa o joelho trabalhar.",
            "Se deu tempo para desbloquear, dá tempo para orar.",
            "O grupo não vai acabar sem sua mensagem. Vai orar.",
            "Seu streak de oração quer falar com você.",
            "O céu não manda spam, mas está te chamando.",
            "Respira. Fecha o app. Abre a oração.",
            "Seu café não é o único jeito de despertar.",
            "Deus te viu online. Falta só responder.",
            "Se você achou esse app, já achou o recado: vai orar.",
            "Seu toque mais importante hoje não é na tela.",
            "O dia nem começou direito e o celular já quer palco.",
            "Antes do caos do dia, cinco minutos de paz com Deus.",
            "A timeline continua. Sua alma agradece se você parar.",
            "Seu dedo quer swipe. Seu coração quer silêncio.",
            "Nem tudo que vibra merece sua atenção. Ore.",
            "Você não precisa checar tudo agora. Comece pela oração.",
            "Se abriu isso, já recebeu o empurrãozinho do céu.",
            "Hoje o modo avião não resolve; oração resolve.",
            "O mundo grita. Deus fala baixo. Chega mais perto.",
            "O relógio corre, mas ainda dá tempo de falar com Deus.",
            "A pressa quer mandar. A oração quer alinhar.",
            "Seu primeiro clique do dia pode ser um amém."
        ],
        .biblical: [
            "Busque primeiro o Reino. Mateus 6:33.",
            "Ore sem cessar. 1 Tessalonicenses 5:17.",
            "Aquiete o coração e reconheça quem Deus é. Salmo 46:10.",
            "Lance sobre Ele a sua ansiedade. 1 Pedro 5:7.",
            "Perto está o Senhor dos que o invocam. Salmo 145:18.",
            "Peça com fé. Tiago 1:5-6.",
            "Entre no secreto e fale com o Pai. Mateus 6:6.",
            "O Senhor ouve quando você clama. Jeremias 33:3.",
            "Confie de todo o coração. Provérbios 3:5.",
            "Seu socorro vem do Senhor. Salmo 121:2.",
            "Derrame diante dEle o coração. Salmo 62:8.",
            "Fale com Deus e a paz guardará você. Filipenses 4:6-7.",
            "Quem espera no Senhor renova as forças. Isaías 40:31.",
            "O Pai sabe do que você precisa. Mateus 6:8.",
            "Permaneça em Cristo e frutifique. João 15:5.",
            "A misericórdia do Senhor se renova hoje. Lamentações 3:22-23.",
            "Clame, e Ele responderá. Jeremias 33:3.",
            "O Senhor é refúgio no começo deste dia. Salmo 91.",
            "Apresente seus caminhos ao Senhor. Salmo 37:5.",
            "Sua fraqueza encontra força na graça. 2 Coríntios 12:9.",
            "O Espírito ajuda até quando faltam palavras. Romanos 8:26.",
            "Vigie e ore. Mateus 26:41.",
            "A alegria do Senhor é sua força. Neemias 8:10.",
            "O Senhor guia quem confia nEle. Salmo 32:8.",
            "Firme o coração na presença de Deus. Salmo 27:14.",
            "Quem habita no esconderijo encontra descanso. Salmo 91:1.",
            "Não ande ansioso; ore. Filipenses 4:6.",
            "A palavra e a oração endireitam o dia.",
            "Levante cedo o coração diante do Senhor. Lamentações 2:19.",
            "Deus dá sabedoria a quem pede. Tiago 1:5."
        ],
        .gentle: [
            "Seu momento com Deus está te esperando com calma.",
            "Hoje ainda cabe um silêncio santo no seu dia.",
            "Separe esse instante e entregue o coração.",
            "Antes das tarefas, receba paz.",
            "Deus não está com pressa; venha como você está.",
            "Talvez a alma só precise de alguns minutos diante do Pai.",
            "Seu dia pode começar mais leve com oração.",
            "Há graça suficiente para hoje, comece nela.",
            "Fique um pouco em silêncio e deixe Deus organizar dentro.",
            "Um coração alinhado muda o resto do dia.",
            "Ore primeiro. O resto encontra lugar.",
            "Seu interior também precisa ser cuidado nesta manhã.",
            "Há descanso na presença de Deus.",
            "Talvez o melhor começo do dia seja simplesmente orar.",
            "Você não precisa carregar tudo sozinho hoje.",
            "Entre nesse momento com sinceridade, não com perfeição.",
            "Oração também é abrigo.",
            "Deus escuta até o que você ainda não conseguiu nomear.",
            "Reserve esse tempo e deixe a paz pousar.",
            "Seu coração merece esse encontro.",
            "Hoje ainda não é tarde para falar com Deus.",
            "Uma oração simples já muda o rumo do dia.",
            "Chegue com gratidão, com cansaço ou com dúvidas. Só chegue.",
            "Há consolo para você neste momento.",
            "Comece o dia por dentro.",
            "Seu espírito também precisa de bom-dia.",
            "Deus continua perto. Dê esse passo.",
            "Oração é pausa, fôlego e direção.",
            "Sente, respira e fala com o Pai.",
            "O céu sempre abre espaço para sua oração."
        ],
        .direct: [
            "Pare e ore agora.",
            "Antes de qualquer app, fale com Deus.",
            "Seu próximo passo é oração.",
            "Hoje não pule esse momento.",
            "Chega de adiar. Ore.",
            "Abra a oração antes de abrir o resto.",
            "Seu dia precisa de alinhamento. Ore.",
            "Faça isso primeiro.",
            "Menos desculpa, mais presença.",
            "Volte o coração para Deus agora.",
            "Esse bloqueio só termina depois da oração.",
            "Não negocie o essencial.",
            "Ore antes do barulho do dia.",
            "Dê a Deus os primeiros minutos.",
            "Respire e comece.",
            "O momento é agora.",
            "Faça silêncio e ore.",
            "Feche a distração. Abra a devoção.",
            "Seu coração precisa liderar o dia.",
            "Prioridade do dia: oração.",
            "Não espere vontade; comece.",
            "O app pode esperar. A oração não.",
            "Fale com Deus antes de falar com o mundo.",
            "Você já sabe o que precisa fazer.",
            "Volte para o centro. Ore.",
            "Tire alguns minutos e cumpra esse encontro.",
            "Comece pelo que sustenta todo o resto.",
            "Hoje o primeiro sim é para Deus.",
            "Seu desbloqueio passa pela oração.",
            "Esse tempo é sagrado. Respeite."
        ],
        .poetic: [
            "Antes do ruído, escolha o rio manso da oração.",
            "Deixe a manhã encontrar seu coração ajoelhado.",
            "Há luz mais funda do que a da tela.",
            "O dia floresce melhor depois de uma oração.",
            "Faça do silêncio uma porta.",
            "A alma também amanhece quando ora.",
            "Entre no secreto e deixe a paz acender.",
            "Toda manhã pede uma direção invisível.",
            "Antes do caminho, receba o norte.",
            "Que seus primeiros minutos tenham eternidade.",
            "O coração encontra casa quando ora.",
            "Há um jardim interior esperando cultivo.",
            "A oração penteia os pensamentos antes da pressa.",
            "O céu gosta de encontros simples.",
            "Quando você ora, o dia ganha raiz.",
            "Leve sua manhã ao altar como quem acende uma vela.",
            "Faça do começo do dia um lugar santo.",
            "A oração abre janela para dentro.",
            "Que a calma fale antes das notificações.",
            "Seu coração foi feito para respirar presença.",
            "Há um amanhecer que só acontece na alma.",
            "Oração é o fio de ouro do dia.",
            "Antes de correr, aprenda a repousar em Deus.",
            "O invisível também sustenta a rotina.",
            "O dia fica mais inteiro quando começa no eterno.",
            "Deixe Deus costurar paz na sua manhã.",
            "Ore, e o caos perde o trono.",
            "Há beleza em começar o dia ajoelhando por dentro.",
            "Seu espírito também precisa de horizonte.",
            "A oração é a primeira música de um dia bem vivido."
        ],
        .wakeUp: [
            "Bom dia. Antes de tudo, ore.",
            "Acordou? Então alinhe o coração.",
            "Comece o dia falando com Deus.",
            "Sua manhã já começou. Sua oração também precisa.",
            "Antes do café, uma conversa com o Pai.",
            "Desperte por inteiro: corpo, mente e espírito.",
            "Hoje começa melhor com oração.",
            "Levante o coração antes da agenda.",
            "Seu despertador tocou. Agora deixe a alma despertar.",
            "Abra a manhã com gratidão.",
            "Primeiros minutos, primeira prioridade.",
            "O dia pede direção desde cedo.",
            "Antes da correria, consagre a manhã.",
            "Não entregue sua manhã à distração.",
            "A primeira voz do dia pode ser a da oração.",
            "Acorde para a presença de Deus.",
            "Traga Deus para o começo do seu dia.",
            "Ainda é cedo o suficiente para começar certo.",
            "Sua rotina agradece por uma oração antes.",
            "O amanhecer é um bom lugar para encontrar Deus.",
            "Hoje tem direção reservada para você.",
            "Faça da manhã um altar.",
            "O dia abre melhor quando o coração abre primeiro.",
            "Dê ao Senhor o início do seu caminho.",
            "Não comece vazio. Ore.",
            "Sua manhã não precisa começar atropelada.",
            "Há sabedoria disponível para agora.",
            "Levante, respire, ore.",
            "Antes de responder o mundo, responda ao céu.",
            "Hoje a manhã pede presença, não pressa."
        ],
        .discipline: [
            "Disciplina também é adoração.",
            "Nem sempre dá vontade; ainda assim vale a pena.",
            "O que é prioridade aparece no começo do dia.",
            "Construa constância um minuto de cada vez.",
            "Firmeza também se aprende na oração.",
            "Seu futuro também é moldado por esses minutos.",
            "Quem protege a manhã protege o dia.",
            "Consistência espiritual começa no simples.",
            "Hoje é mais uma chance de fortalecer o hábito certo.",
            "Seu coração precisa de treino santo.",
            "Pequenos minutos, grande direção.",
            "A constância que você quer começa agora.",
            "Volte ao essencial e permaneça.",
            "Não alimente só a pressa.",
            "Você está formando um caminho de fé.",
            "Todo dia é uma nova repetição do que importa.",
            "Ore mesmo quando parecer pequeno.",
            "O invisível também constrói caráter.",
            "Sua disciplina de hoje sustenta seu amanhã.",
            "Perseverança também tem hora marcada.",
            "Faça o que fortalece, não só o que distrai.",
            "Esse hábito pode mudar seus dias.",
            "Oração frequente, coração firme.",
            "Treine a alma a voltar para Deus.",
            "Quem começa no secreto caminha com mais clareza.",
            "Sua rotina espiritual merece compromisso.",
            "Volte ao altar mais uma vez.",
            "Fé também se pratica no calendário.",
            "Hoje você pode escolher profundidade.",
            "Seu melhor foco começa em oração."
        ]
    ]

    static let all: [String] = PrayerEncouragementGroup.allCases.flatMap { phrases(for: $0) }

    static let totalCount: Int = all.count

    static func phrases(for group: PrayerEncouragementGroup) -> [String] {
        grouped[group] ?? []
    }

    static func randomPhrase(
        in groups: [PrayerEncouragementGroup] = PrayerEncouragementGroup.allCases
    ) -> String {
        let pool = pool(for: groups)
        return pool.randomElement() ?? fallback
    }

    static func dailyPhrase(
        on date: Date = .now,
        in groups: [PrayerEncouragementGroup] = PrayerEncouragementGroup.allCases
    ) -> String {
        let pool = pool(for: groups)
        guard !pool.isEmpty else { return fallback }
        let ordinal = (Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1) - 1
        return pool[ordinal % pool.count]
    }

    private static func pool(for groups: [PrayerEncouragementGroup]) -> [String] {
        let selectedGroups = groups.isEmpty ? PrayerEncouragementGroup.allCases : groups
        return selectedGroups.flatMap { phrases(for: $0) }
    }

    private static let fallback = "Agora é tempo de oração."
}
