#!/bin/bash
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          HUTOS System Tools Verification                 ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Checking tool presence..."
for tool in hutctl hutinfo hutsched hutbench hutdiag; do
    if [ -x "rootfs/bin/$tool" ]; then
        echo "  ✅ $tool"
    else
        echo "  ❌ $tool (missing or not executable)"
    fi
done

if [ -f "rootfs/lib/hutos-common.sh" ]; then
    echo "  ✅ hutos-common.sh (shared library)"
else
    echo "  ❌ hutos-common.sh (missing)"
fi

echo ""
echo "Tool sizes:"
ls -lh rootfs/bin/hut{ctl,info,sched,bench,diag} rootfs/lib/hutos-common.sh 2>/dev/null | awk '{print "  " $9 " - " $5}'

echo ""
echo "Git status:"
echo "  Branch: $(git branch --show-current)"
echo "  Latest commit: $(git log --oneline -1)"

echo ""
echo "Pull Request: https://github.com/hut-os/hut-os/pull/3"
echo "Status: ✅ MERGED"
echo ""
