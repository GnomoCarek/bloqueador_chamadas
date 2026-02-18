# Bloqueador de Chamadas

Este aplicativo foi desenvolvido em Flutter com o objetivo de oferecer uma camada de privacidade e segurança para o usuário, permitindo o bloqueio automático de chamadas telefônicas de números que não estejam salvos na agenda de contatos do dispositivo.

## Funcionalidades

O aplicativo utiliza a API de Call Screening do Android para identificar chamadas recebidas em tempo real. A lógica de funcionamento segue estes critérios:

1. O aplicativo solicita permissão para acessar os contatos e o estado do telefone.
2. O usuário deve definir o aplicativo como o serviço de triagem de chamadas padrão (Default Call Screening App) nas configurações do Android.
3. Quando uma chamada é recebida, o serviço verifica se o número de origem consta na lista de contatos.
4. Caso o número não seja encontrado, a chamada é rejeitada silenciosamente, sem gerar notificações ou interrupções para o usuário.

## Tecnologias Utilizadas

- Flutter: Interface de usuário e lógica multiplataforma.
- Kotlin (Android): Implementação do CallScreeningService para integração nativa com o sistema de telefonia.
- MethodChannel: Comunicação entre a interface Flutter e os recursos nativos do Android.

## Como Utilizar

### Pré-requisitos

- Dispositivo Android com versão 10 (API 29) ou superior.
- Flutter SDK instalado no ambiente de desenvolvimento.

### Instalação

1. Clone o repositório:
   git clone https://github.com/GnomoCarek/bloqueador_chamadas.git

2. Acesse o diretório do projeto:
   cd bloqueador_chamadas

3. Instale as dependências:
   flutter pub get

4. Execute o aplicativo:
   flutter run

### Configuração no Dispositivo

Ao abrir o aplicativo pela primeira vez:
1. Conceda as permissões de Telefone e Contatos quando solicitado.
2. Clique no botão central (Escudo) para ativar o bloqueio.
3. Confirme a alteração para que o aplicativo seja o serviço de triagem padrão do sistema.

## Observações Técnicas

O bloqueio ocorre no nível de sistema, o que garante baixo consumo de bateria, pois o aplicativo não precisa permanecer aberto em primeiro plano para funcionar. O Android acorda o serviço de triagem apenas no momento exato em que uma chamada é recebida.
