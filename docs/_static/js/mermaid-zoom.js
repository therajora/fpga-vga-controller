document.addEventListener("DOMContentLoaded", function() {
    // Função para adicionar pan-zoom aos SVGs do Mermaid
    function addPanZoom() {
        // Encontra todos os SVGs dentro de divs com classe 'mermaid'
        const svgs = document.querySelectorAll(".mermaid svg");
        
        if (svgs.length === 0) {
            // Se ainda não renderizou, tenta novamente em breve
            // O Mermaid renderiza de forma assíncrona
            setTimeout(addPanZoom, 200);
            return;
        }

        svgs.forEach((svg) => {
            if (svg.getAttribute("data-pan-zoom-enabled")) return;
            
            // Estilo para garantir visibilidade e container correto
            svg.style.maxWidth = "100%";
            svg.style.height = "500px"; // Altura fixa inicial ajuda no pan/zoom
            svg.style.border = "1px solid #eee"; // Borda sutil para indicar área interativa

            // Garante que o pai tenha posição relativa para os botões absolutos e sem scroll
            if (svg.parentNode) {
                svg.parentNode.style.position = 'relative';
                svg.parentNode.style.overflow = 'hidden'; // Remove scrollbars externas feias
            }

            try {
                // Inicializa svg-pan-zoom
                const panZoomInstance = svgPanZoom(svg, {
                    zoomEnabled: true,
                    controlIconsEnabled: false, // Desabilita ícones nativos (que são grandes/feios)
                    fit: true,
                    center: true,
                    minZoom: 0.1,
                    maxZoom: 10,
                    dblClickZoomEnabled: true, // Zoom duplo clique
                    mouseWheelZoomEnabled: true // Zoom com scroll
                });
                
                svg.setAttribute("data-pan-zoom-enabled", "true");

                // --- Adicionar controles customizados minimalistas ---
                
                // Cria container para os botões
                const controls = document.createElement('div');
                controls.className = 'mermaid-controls';
                controls.style.position = 'absolute';
                controls.style.right = '10px';
                controls.style.bottom = '10px';
                controls.style.zIndex = '10';
                controls.style.display = 'flex';
                controls.style.flexDirection = 'column'; // Vertical para ocupar menos espaço horizontal
                controls.style.gap = '4px';
                controls.style.opacity = '0'; // Invisível por padrão
                controls.style.transition = 'opacity 0.3s ease';

                // Mostrar controles apenas quando o mouse estiver sobre o SVG ou os controles
                const showControls = () => controls.style.opacity = '0.8';
                const hideControls = () => controls.style.opacity = '0';

                svg.addEventListener('mouseenter', showControls);
                svg.addEventListener('mouseleave', (e) => {
                    // Só esconde se o mouse não foi para os controles
                    if (!controls.contains(e.relatedTarget)) hideControls();
                });
                controls.addEventListener('mouseenter', showControls);
                controls.addEventListener('mouseleave', hideControls);

                // Função auxiliar para criar botão
                const createBtn = (text, onClick, title) => {
                    const btn = document.createElement('button');
                    btn.innerHTML = text;
                    btn.title = title;
                    btn.style.width = '20px';
                    btn.style.height = '20px';
                    btn.style.padding = '0';
                    btn.style.border = '1px solid #ccc';
                    btn.style.background = 'rgba(255, 255, 255, 0.9)';
                    btn.style.cursor = 'pointer';
                    btn.style.borderRadius = '3px';
                    btn.style.fontSize = '12px';
                    btn.style.fontWeight = 'bold';
                    btn.style.lineHeight = '18px';
                    btn.style.color = '#555';
                    btn.style.boxShadow = '0 1px 2px rgba(0,0,0,0.1)';
                    
                    btn.onmouseenter = () => {
                        btn.style.background = '#fff';
                        btn.style.color = '#000';
                        btn.style.borderColor = '#999';
                    };
                    btn.onmouseleave = () => {
                        btn.style.background = 'rgba(255, 255, 255, 0.9)';
                        btn.style.color = '#555';
                        btn.style.borderColor = '#ccc';
                    };

                    btn.onclick = (e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        onClick();
                    };
                    return btn;
                };

                controls.appendChild(createBtn('+', () => panZoomInstance.zoomIn(), 'Zoom In'));
                controls.appendChild(createBtn('-', () => panZoomInstance.zoomOut(), 'Zoom Out'));
                controls.appendChild(createBtn('⟲', () => panZoomInstance.reset(), 'Resetar'));

                if (svg.parentNode) {
                    svg.parentNode.appendChild(controls);
                }

            } catch (e) {
                console.error("Erro ao inicializar pan-zoom no Mermaid:", e);
            }
        });
    }

    // Tenta inicializar quando a janela carregar totalmente (imagens, scripts, etc)
    window.addEventListener('load', function() {
        // Pequeno delay para garantir que o script do mermaid rodou
        setTimeout(addPanZoom, 500);
    });
});
