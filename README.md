# Shield Call - Bloqueador de Chamadas Inteligente

Este aplicativo foi desenvolvido em Flutter com o objetivo de oferecer uma camada de privacidade e segurança para o usuário, permitindo o bloqueio automático de chamadas telefônicas de números que não estejam salvos na agenda de contatos do dispositivo.

## Novas Funcionalidades e Melhorias

Implementamos uma série de atualizações focadas em experiência do usuário e robustez:

- **Interface Cyber Security Dark:** Novo design moderno com estética de segurança cibernética, gradientes profundos e cores neon (Ciano/Coral).
- **Contador de Bloqueios em Tempo Real:** Dashboard que exibe a quantidade total de chamadas interceptadas pelo sistema.
- **Persistência de Estado:** O aplicativo agora utiliza `shared_preferences` para lembrar se a proteção está ativa ou inativa, mesmo após reiniciar o dispositivo ou fechar o app.
- **Animações de Feedback:** Efeito de pulso neon no botão principal para indicar monitoramento ativo.
- **Sincronização Automática:** O contador de bloqueios é atualizado instantaneamente sempre que o usuário retorna ao aplicativo.

## Como Funciona

O aplicativo utiliza a API de Call Screening do Android (API 29+) para identificar chamadas recebidas em tempo real:

1. **Permissões:** O app solicita acesso aos contatos e ao estado do telefone.
2. **Serviço Padrão:** O usuário define o Shield Call como o serviço de triagem de chamadas padrão (Default Call Screening App).
3. **Triagem Inteligente:** Quando uma chamada é recebida, o serviço nativo verifica se o número consta na agenda de contatos.
4. **Bloqueio Silencioso:** Se o número for desconhecido, a chamada é rejeitada silenciosamente, sem interrupções, e o contador de bloqueios é incrementado.

## Tecnologias Utilizadas

- **Flutter:** Interface de usuário e lógica de estado.
- **Kotlin (Android 10+):** Implementação do `CallScreeningService` para integração nativa profunda.
- **SharedPreferences:** Armazenamento local para persistência de configurações e contagem de bloqueios.
- **MethodChannel:** Ponte de comunicação entre Dart (Flutter) e o código nativo Android.

## Como Utilizar

### Pré-requisitos

- Dispositivo Android com versão 10 (API 29) ou superior.
- Flutter SDK instalado.

### Instalação

1. Clone o repositório:
   ```bash
   git clone https://github.com/GnomoCarek/bloqueador_chamadas.git
   ```

2. Instale as dependências:
   ```bash
   flutter pub get
   ```

3. Execute o aplicativo:
   ```bash
   flutter run --release
   ```

### Configuração no Dispositivo

Ao abrir o aplicativo pela primeira vez:
1. Conceda as permissões de **Telefone** e **Contatos**.
2. Clique no botão central (Escudo) para ativar a proteção.
3. Confirme a alteração para tornar o Shield Call o serviço de triagem padrão do sistema.

## Observações Técnicas

O bloqueio ocorre no nível de sistema, garantindo **baixíssimo consumo de bateria**. O Android acorda o serviço de triagem apenas no momento exato de uma chamada recebida, permitindo que o aplicativo permaneça fechado sem perder sua eficácia.
