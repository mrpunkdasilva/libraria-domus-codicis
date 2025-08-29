# Atividade 1

Neste documento, vou detalhar o processo que utilizei para integrar um sprite (uma imagem) em uma interface de usuário, habilitar seu movimento vertical através das teclas de seta e reproduzir um som a cada interação. Este guia é aplicável a projetos que utilizam tecnologias XAML, como Uno Platform ou WinUI, que é o caso do nosso jogo.

## 1. Adicionando o Sprite à Interface de Usuário (MainPage.xaml)

Para que pudéssemos visualizar e manipular o sprite, decidi utilizar o controle `Image` dentro do arquivo `MainPage.xaml`. Foi crucial que este `Image` estivesse aninhado em um painel de layout que suportasse posicionamento e transformação, como um `Grid` ou `Canvas`, para permitir o movimento de forma flexível.

```xml
<Page
    x:Class="SpaceInvaders.Presentation.MainPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    IsTabStop="True"  FocusVisualPrimaryBrush="Transparent" FocusVisualSecondaryBrush="Transparent"> <!-- Adicionei isso para garantir o foco do teclado -->

    <Grid>
        <!-- Outros elementos da UI existentes no seu projeto -->

        <Image x:Name="PlayerSprite"
               Source="ms-appx:///Assets/sprites/player/index.png"
               Width="50" Height="50"
               VerticalAlignment="Center"
               HorizontalAlignment="Center"
               RenderTransformOrigin="0.5,0.5">
            <Image.RenderTransform>
                <!-- Usei TranslateTransform para mover o elemento ao alterar suas propriedades X e Y -->
                <TranslateTransform x:Name="PlayerTranslateTransform" />
            </Image.RenderTransform>
        </Image>
    </Grid>
</Page>
```

### Detalhamento dos Elementos XAML que Adicionei:

*   **`<Page IsTabStop="True" FocusVisualPrimaryBrush="Transparent" FocusVisualSecondaryBrush="Transparent">`**:
    *   `IsTabStop="True"`: Achei essencial adicionar isso para que a página pudesse receber o foco do teclado e, consequentemente, capturar eventos de tecla como `KeyDown`.
    *   `FocusVisualPrimaryBrush` e `FocusVisualSecondaryBrush`: Defini esses como `Transparent` para evitar que um contorno visual de foco aparecesse ao redor da página. Em jogos, geralmente não queremos esse tipo de feedback visual padrão.
*   **`<Image x:Name="PlayerSprite" ...>`**:
    *   `x:Name="PlayerSprite"`: Atribuí um nome único ao controle `Image`. Isso me permitiu referenciá-lo e manipulá-lo diretamente no código C# (no `MainPage.xaml.cs`).
    *   `Source="ms-appx:///Assets/sprites/player/index.png"`: Defini o caminho para o arquivo de imagem do sprite. O prefixo `ms-appx:///` indica que o recurso está empacotado com o aplicativo. Sempre me certifico de que o caminho relativo (`Assets/sprites/player/index.png`) esteja correto e que a imagem esteja incluída como um recurso no projeto.
    *   `Width="50" Height="50"`: Defini as dimensões do sprite em unidades de pixel independentes de dispositivo. Você pode ajustar esses valores para corresponder ao tamanho real da sua imagem ou ao tamanho desejado no jogo.
    *   `VerticalAlignment="Center"` e `HorizontalAlignment="Center"`: Posicionei o sprite inicialmente no centro do seu contêiner (`Grid` neste caso).
    *   `RenderTransformOrigin="0.5,0.5"`: Defini o ponto de origem para transformações (como rotação ou translação). `0.5,0.5` (centro) é um valor comum para transformações que devem ocorrer a partir do centro do objeto.
*   **`<Image.RenderTransform>` e `<TranslateTransform x:Name="PlayerTranslateTransform" />`**:
    *   `RenderTransform`: Esta é uma propriedade que me permite aplicar transformações visuais (como translação, rotação, escala) a um elemento.
    *   `TranslateTransform`: É uma transformação específica que permite mover um elemento ao longo dos eixos X e Y. Ao dar um `x:Name` a ele, consigo acessar e modificar suas propriedades `X` e `Y` no código C# para mover o sprite.

## 2. Implementando a Lógica de Movimento e Som (MainPage.xaml.cs)

No arquivo code-behind `MainPage.xaml.cs`, implementei a lógica para capturar as entradas do teclado, mover o sprite e reproduzir o som associado. Veja como fiz:

```csharp
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Input;
using Windows.System; // Necessário para VirtualKey
using Windows.Media.Playback; // Necessário para MediaPlayer
using Windows.Media.Core; // Necessário para MediaSource
using System;

namespace SpaceInvaders.Presentation;

public sealed partial class MainPage : Page
{
    private const double MovementSpeed = 10.0; // Defini a velocidade de movimento do sprite em pixels por pressionamento de tecla.
    private MediaPlayer _moveSoundPlayer; // Criei uma instância do MediaPlayer para gerenciar a reprodução do som de movimento.

    public MainPage()
    {
        this.InitializeComponent();
        this.Loaded += MainPage_Loaded; // Assinei o evento Loaded para inicializações quando a página é carregada.
        this.Unloaded += MainPage_Unloaded; // Assinei o evento Unloaded para liberar recursos quando a página é descarregada.
        this.KeyDown += MainPage_KeyDown; // Assinei o evento KeyDown para capturar pressionamentos de tecla.
        
        // Inicializei o MediaPlayer para o som de movimento.
        _moveSoundPlayer = new MediaPlayer();
        // Defini a fonte do som. O caminho 'ms-appx:///' aponta para recursos empacotados com o aplicativo.
        _moveSoundPlayer.Source = MediaSource.CreateFromUri(new Uri("ms-appx:///Assets/sounds/player/shoot/sound1.mp3")); 
    }

    /// <summary>
    /// Manipula o evento Loaded da página.
    /// Usei para iniciar a música de fundo e assinar eventos do MediaPlayer.
    /// </summary>
    private void MainPage_Loaded(object sender, RoutedEventArgs e)
    {
        // Me certifiquei de que a página tem foco para capturar eventos de teclado.
        // Isso é importante se a página não for o elemento inicial com foco.
        this.Focus(FocusState.Programmatic); 

        // ... (código existente para música de fundo, se houver)
        // Exemplo: BackgroundMusicPlayer.MediaPlayer.MediaEnded += MediaPlayer_MediaEnded;
        // Exemplo: BackgroundMusicPlayer.MediaPlayer.Play();
    }

    /// <summary>
    /// Manipula o evento Unloaded da página.
    /// Usei para pausar a música de fundo e liberar recursos do MediaPlayer.
    /// </summary>
    private void MainPage_Unloaded(object sender, RoutedEventArgs e)
    {
        // ... (código existente para música de fundo, se houver)
        // Exemplo: BackgroundMusicPlayer.MediaPlayer.Pause();
        // Exemplo: BackgroundMusicPlayer.MediaPlayer.MediaEnded -= MediaPlayer_MediaEnded;
        
        // Liberei os recursos do MediaPlayer do som de movimento para evitar vazamentos de memória.
        _moveSoundPlayer.Dispose(); 
    }

    /// <summary>
    /// Manipula o evento KeyDown para detectar pressionamentos de tecla e mover o sprite.
    /// </summary>
    private void MainPage_KeyDown(object sender, KeyRoutedEventArgs e)
    {
        // Obtive a posição Y atual do sprite.
        double newY = PlayerTranslateTransform.Y;

        // Verifiquei qual tecla foi pressionada.
        switch (e.OriginalKey)
        {
            case VirtualKey.Up: // Tecla Seta para Cima
                newY -= MovementSpeed; // Movi o sprite para cima (diminuindo o valor Y).
                PlayMoveSound(); // Reproduzi o som de movimento.
                break;
            case VirtualKey.Down: // Tecla Seta para Baixo
                newY += MovementSpeed; // Movi o sprite para baixo (aumentando o valor Y).
                PlayMoveSound(); // Reproduzi o som de movimento.
                break;
            // Você pode adicionar outros casos para movimento horizontal (Left, Right) ou outras ações.
        }

        // Limitei o movimento do sprite para que ele permanecesse dentro de uma área visível.
        // Os valores -200 e 200 são exemplos; você precisará ajustá-los com base no tamanho da sua tela e nas dimensões do sprite.
        // Math.Clamp garante que newY esteja sempre entre o valor mínimo e máximo especificados.
        newY = Math.Clamp(newY, -200, 200);

        // Apliquei a nova posição Y ao TranslateTransform do sprite.
        PlayerTranslateTransform.Y = newY;
    }

    /// <summary>
    /// Reproduz o som de movimento do sprite.
    /// </summary>
    private void PlayMoveSound()
    {
        // Reiniciei a posição do MediaPlayer para o início. Isso é crucial para permitir que o som
        // seja reproduzido múltiplas vezes rapidamente, mesmo que a reprodução anterior não tenha terminado.
        _moveSoundPlayer.Position = TimeSpan.Zero;
        _moveSoundPlayer.Play(); // Iniciei a reprodução do som.
    }

    // ... (outros métodos existentes na sua MainPage.xaml.cs, como MediaPlayer_MediaEnded, OnNavigatedTo, etc.)
}
```

### Detalhamento da Lógica C# que Implementei:

*   **`MovementSpeed`**: Defini esta constante `double` para controlar a quantidade de pixels que o sprite se moverá a cada pressionamento de tecla. Você pode ajustar este valor para controlar a sensibilidade do movimento.
*   **`_moveSoundPlayer`**: Criei uma instância da classe `MediaPlayer` do namespace `Windows.Media.Playback`. Esta classe é a que utilizo para carregar e reproduzir arquivos de áudio.
*   **Construtor `MainPage()`**:
    *   `this.InitializeComponent()`: Este é o método gerado automaticamente que inicializa os componentes XAML definidos na `MainPage.xaml`.
    *   `this.Loaded += MainPage_Loaded;`: Assinei o evento `Loaded` da página. O método `MainPage_Loaded` será chamado quando a página for carregada e estiver pronta para interação.
    *   `this.Unloaded += MainPage_Unloaded;`: Assinei o evento `Unloaded`. O método `MainPage_Unloaded` será chamado quando a página for descarregada, e é o local ideal para liberar recursos.
    *   `this.KeyDown += MainPage_KeyDown;`: Assinei o evento `KeyDown`. O método `MainPage_KeyDown` será invocado sempre que uma tecla for pressionada enquanto a página (ou um de seus elementos filhos) tiver o foco.
    *   **Inicialização do `_moveSoundPlayer`**: Instanciei o `MediaPlayer` e defini sua propriedade `Source` usando `MediaSource.CreateFromUri` com um `Uri` apontando para o arquivo de som. O caminho `ms-appx:///` é o que usamos para referenciar recursos empacotados no aplicativo.
*   **`MainPage_Loaded(object sender, RoutedEventArgs e)`**:
    *   `this.Focus(FocusState.Programmatic);`: Garanti que a página recebesse o foco do teclado programaticamente quando é carregada. Isso é crucial para que os eventos `KeyDown` sejam disparados corretamente.
*   **`MainPage_Unloaded(object sender, RoutedEventArgs e)`**:
    *   `_moveSoundPlayer.Dispose();`: É de extrema importância que eu chame o método `Dispose()` em objetos `MediaPlayer` quando eles não são mais necessários. Isso libera os recursos de áudio subjacentes e evita vazamentos de memória, especialmente em cenários onde a página pode ser carregada e descarregada múltiplas vezes.
*   **`MainPage_KeyDown(object sender, KeyRoutedEventArgs e)`**:
    *   `double newY = PlayerTranslateTransform.Y;`: Obtive a posição vertical atual do sprite a partir do `TranslateTransform`.
    *   `switch (e.OriginalKey)`: Utilizei uma estrutura `switch` para verificar qual `VirtualKey` (tecla virtual) foi pressionada.
        *   `case VirtualKey.Up:`: Se a seta para cima for pressionada, `newY` é decrementado por `MovementSpeed` (movendo o sprite para cima).
        *   `case VirtualKey.Down:`: Se a seta para baixo for pressionada, `newY` é incrementado por `MovementSpeed` (movendo o sprite para baixo).
        *   `PlayMoveSound();`: Em ambos os casos de movimento, chamei o método `PlayMoveSound()` para reproduzir o áudio.
    *   `newY = Math.Clamp(newY, -200, 200);`: Esta linha é fundamental para manter o sprite dentro de limites visíveis na tela. `Math.Clamp` restringe o valor de `newY` entre um mínimo (`-200`) e um máximo (`200`). Você precisará ajustar esses valores com base nas dimensões da sua área de jogo e do sprite para evitar que ele saia da tela.
    *   `PlayerTranslateTransform.Y = newY;`: Apliquei a nova posição calculada à propriedade `Y` do `TranslateTransform`, o que visualmente move o sprite na interface.
*   **`PlayMoveSound()`**:
    *   `_moveSoundPlayer.Position = TimeSpan.Zero;`: Esta linha é vital para permitir a reprodução repetida do som. Se o som já estiver tocando ou tiver terminado, redefinir sua `Position` para `TimeSpan.Zero` (o início) permite que ele seja reproduzido novamente imediatamente. Sem isso, o som só tocaria uma vez até terminar.
    *   `_moveSoundPlayer.Play();`: Iniciei a reprodução do som.

## 3. Considerações Adicionais e Boas Práticas que Levei em Conta:

*   **Foco do Teclado**:
    *   Como mencionei, a `Page` ou um de seus elementos filhos deve ter o foco para que os eventos `KeyDown` sejam disparados. A adição de `IsTabStop="True"` na `Page` e a chamada `this.Focus(FocusState.Programmatic);` no `MainPage_Loaded` são as formas mais diretas que encontrei para garantir isso.
    *   Em cenários mais complexos, você pode precisar gerenciar o foco explicitamente, especialmente se houver outros controles interativos na página.
*   **Limites de Tela e Colisões**:
    *   A lógica `Math.Clamp` é um ponto de partida. Para um jogo completo, você precisará de um sistema mais robusto para gerenciar os limites da tela e detectar colisões com outros objetos. Isso geralmente envolve calcular as coordenadas dos cantos do sprite e compará-las com as bordas da tela ou de outros elementos.
*   **Caminho dos Recursos (Imagens e Sons)**:
    *   Sempre verifico se os caminhos `ms-appx:///Assets/...` estão corretos e se os arquivos de imagem e som estão configurados como "Conteúdo" (Content) ou "Recurso" (Resource) nas propriedades de build do seu projeto, dependendo da plataforma (WinUI, UWP, Uno Platform).
*   **Performance e Animações Avançadas**:
    *   Para jogos com muitos objetos em movimento, animações complexas ou que exigem alta taxa de quadros, a manipulação direta de `RenderTransform` pode não ser a mais eficiente.
    *   **`CompositionPropertySet` e `ExpressionAnimation`**: Para cenários de alta performance, especialmente em plataformas como WinUI/UWP, é recomendado usar a camada de composição. Isso permite que as animações sejam executadas diretamente na GPU, fora da thread da UI, resultando em animações mais suaves e responsivas. Embora mais complexo de implementar inicialmente, oferece ganhos significativos de performance.
    *   Para este exemplo simples, `TranslateTransform` é perfeitamente adequado.
*   **Gerenciamento de Estado do Jogo**:
    *   Em um jogo real, o movimento do jogador e a reprodução de sons seriam parte de um ciclo de jogo maior, onde a lógica de atualização (update) e renderização (draw) é executada continuamente. Os eventos de teclado seriam usados para atualizar o estado do jogador, que então seria processado no ciclo de jogo.
*   **Organização de Código**:
    *   À medida que o jogo cresce, considero mover a lógica de movimento e som para classes separadas (por exemplo, uma classe `Player` que encapsula seu estado e comportamento, e um `SoundManager` para gerenciar todos os sons do jogo) para manter o código limpo e modular.
*   **Depuração**:
    *   Se o sprite não se mover ou o som não tocar, sempre verifico:
        *   Se a `Page` tem foco (`IsTabStop="True"` e `Focus(FocusState.Programmatic)`).
        *   Se os caminhos dos arquivos de imagem e som estão corretos.
        *   Se há erros no console de saída do Visual Studio ou nas ferramentas de depuração do navegador (para Uno Platform WebAssembly).
        *   Uso breakpoints no C# para inspecionar os valores de `newY` e `PlayerTranslateTransform.Y`.

Este guia fornece uma base sólida para implementar o movimento de sprites e a reprodução de sons em seu jogo, seguindo as melhores práticas que adotei para desenvolvimento XAML.

# Atividade 2

Link parar o GitLab: [https://gitlab.com/jala-university1/cohort-4/oficial-pt-programa-o-3-cspr-231.ga.t2.25.m1/se-o-a/gustavo.jesus/capstone](https://gitlab.com/jala-university1/cohort-4/oficial-pt-programa-o-3-cspr-231.ga.t2.25.m1/se-o-a/gustavo.jesus/capstone)