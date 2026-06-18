<template>
  <div @click="increment">{{ count }}</div>
</template>

<script setup>
import { ref } from 'vue';
const count = ref(0);
const increment = () => { count.value++; };
</script>